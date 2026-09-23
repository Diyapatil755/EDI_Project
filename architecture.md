# Admin Panel Architecture

## Overview

Three pieces work together:

| Piece | Role |
|---|---|
| **Firebase Auth** | Checks *who you are* (email + password) |
| **Cloud Firestore** | Stores *what you're allowed to do* (`Admin` collection) and *the data* (`config/geofence`) |
| **HTML pages** | The UI. They talk to Firebase directly from the browser |

**Stack:** plain HTML/JS (ES modules) + Firebase Auth + Firestore + Leaflet (OpenStreetMap)

---

## Data Model

```
Firestore
├── Admin/{uid}            role: "admin"
├── Employees/{uid}        name, email, approved: bool
└── config/geofence        lat, lng, radius, updatedBy, updatedAt
```

- The **document ID in `Admin` must equal the user's Firebase Auth UID**. Existence of that doc is what grants admin access.
- `config/geofence` is a single document: one office, stored as a circle (center + radius in meters).

---

## Flow

### 1. Login (`login.html`)

```
User enters email + password
        │
        ▼
signInWithEmailAndPassword()      ← Stage 1: authentication
        │ fails → show error code
        ▼
getDoc(Admin/{uid})               ← Stage 2: authorization
        │ missing → signOut + "Not an admin"
        ▼
redirect → admin.html
```

**Key idea:** authentication ≠ authorization. Anyone with an account passes stage 1. Only users listed in `Admin` pass stage 2.

### 2. Admin panel (`admin.html`)

```
Page load
   │
   ▼
onAuthStateChanged (route guard)
   │ no user / not in Admin → redirect to login.html
   ▼
loadExisting()  → read config/geofence → redraw saved circle
   │
   ▼
Admin clicks map → marker + circle drawn
Admin drags slider → circle resizes live
   │
   ▼
Save → setDoc(config/geofence, { lat, lng, radius, updatedBy, updatedAt })
```

### 3. Employee-side check (not built yet)

```
Employee app reads config/geofence
        │
        ▼
Gets device GPS position
        │
        ▼
Haversine distance(user, center) <= radius ?
        │
   yes ─┴─ no
 inside    outside
```

```js
function dist(lat1, lon1, lat2, lon2) {
  const R = 6371000, r = x => x * Math.PI / 180;
  const a = Math.sin(r(lat2 - lat1) / 2) ** 2 +
            Math.cos(r(lat1)) * Math.cos(r(lat2)) * Math.sin(r(lon2 - lon1) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}
// inside = dist(userLat, userLng, fence.lat, fence.lng) <= fence.radius
```

---

## Code Breakdown

### `login.html`

| Part | Purpose |
|---|---|
| `import ... from "https://www.gstatic.com/..."` | Loads the Firebase SDK from Google's CDN. Needs `type="module"` and a local server (modules don't load from `file://`) |
| `firebaseConfig` | Identifies which Firebase project to talk to. Not a secret |
| `initializeApp / getAuth / getFirestore` | Connects to the project; gives `auth` (login) and `db` (database) handles |
| `login()` | Two-stage check described above |
| `btn.disabled` | Prevents double submits |

### `admin.html`

| Part | Purpose |
|---|---|
| Route guard (`onAuthStateChanged`) | Redirects non-admins to login. Without it anyone could open `admin.html` directly |
| `L.map()` + `L.tileLayer()` | Leaflet map centered on Pune; loads OpenStreetMap tiles |
| `draw(latlng, r)` | Removes old marker/circle, places new ones |
| `map.on("click")` | Sets the office center |
| Slider `oninput` | Resizes the circle live via `circle.setRadius()` |
| "Use my location" | `navigator.geolocation` (requires HTTPS or localhost) |
| Save | `setDoc()` writes/overwrites `config/geofence` |
| `loadExisting()` | Redraws the saved circle on page load |

---

## Security Rules

The JavaScript checks run in the browser and are **UI convenience only**; anyone can bypass them with dev tools. Firestore rules run on Google's servers and cannot be bypassed.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function isAdmin() {
      return request.auth != null &&
             exists(/databases/$(db)/documents/Admin/$(request.auth.uid));
    }
    match /Admin/{id}      { allow read: if request.auth.uid == id; allow write: if false; }
    match /config/{id}     { allow read: if request.auth != null; allow write: if isAdmin(); }
    match /Employees/{id}  { allow read, write: if isAdmin() || request.auth.uid == id; }
  }
}
```

| Collection | Read | Write |
|---|---|---|
| `Admin` | Own doc only | Nobody (console only) |
| `config` | Any signed-in user (employees need the fence) | Admins only |
| `Employees` | Admins, or the user's own doc | Admins, or the user's own doc |

**Known gap:** the `Employees` rule lets a user write to their own doc, including the `approved` field. An employee could self-approve. Fix by restricting which fields employees may change, or by splitting approval state into an admin-only collection.

---

## Known Limitations

- **Client-side geofence checks can be spoofed.** GPS can be faked on a phone. Acceptable for a college project; a real system needs server-side validation or device attestation.
- **Single office only.** One `geofence` doc means no multiple branches.
- **Circle only.** Irregular buildings or campuses are approximated poorly.
- **Test-mode rules are open to the world** and expire after 30 days. Always publish real rules before submitting.
