import 'dart:convert';
import 'package:crypto/crypto.dart';

class LedgerTransactionDetails {
  final String txHash;
  final int blockNumber;
  final DateTime timestamp;
  final String network;
  final String merkleRoot;
  final bool isConfirmed;

  const LedgerTransactionDetails({
    required this.txHash,
    required this.blockNumber,
    required this.timestamp,
    required this.network,
    required this.merkleRoot,
    required this.isConfirmed,
  });
}

abstract class LedgerService {
  Future<String> anchorAttendance({
    required String uid,
    required DateTime timestamp,
    required String type,
  });

  Future<LedgerTransactionDetails> getTransactionDetails(String txHash);
}

/// Mock Ledger Service designed for seamless replacement by the blockchain teammate.
/// Generates deterministic SHA-256 / keccak-style mock transaction hashes.
class MockLedgerService implements LedgerService {
  final String networkName;

  MockLedgerService({this.networkName = 'Polygon zkEVM Testnet (VIT Pune)'});

  @override
  Future<String> anchorAttendance({
    required String uid,
    required DateTime timestamp,
    required String type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final payload = '$uid:${timestamp.toIso8601String()}:$type';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString().substring(0, 40)}';
  }

  @override
  Future<LedgerTransactionDetails> getTransactionDetails(String txHash) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return LedgerTransactionDetails(
      txHash: txHash,
      blockNumber: 4892104,
      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      network: networkName,
      merkleRoot: '0x9a8f4c2e1189bc44d0382910fa31bced01235478',
      isConfirmed: true,
    );
  }
}
