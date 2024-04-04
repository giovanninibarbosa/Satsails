import 'dart:convert';
import 'dart:isolate';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BitcoinModel {
  final Bitcoin config;

  BitcoinModel(this.config);

  Future<void> sync() async {
    try {
      await config.wallet.sync(config.blockchain!);
    } on FormatException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> asyncSync() async {
    try {
      Isolate.run(() async => {await config.wallet.sync(config.blockchain!)});
    } on FormatException catch (e) {
      debugPrint(e.message);
    }
  }

  Future<AddressInfo> getAddress() async {
    final address = await config.wallet.getAddress(addressIndex: const AddressIndex());
    return address;
  }

  Future<Input> getPsbtInput(LocalUtxo utxo, bool onlyWitnessUtxo) async {
    final input = await config.wallet.getPsbtInput(utxo: utxo, onlyWitnessUtxo: onlyWitnessUtxo);
    return input;
  }

  Future<List<TransactionDetails>> getUnConfirmedTransactions() async {
    List<TransactionDetails> unConfirmed = [];
    final res = await config.wallet.listTransactions(true);
    for (var e in res) {
      if (e.confirmationTime == null) unConfirmed.add(e);
    }
    return unConfirmed;
  }

  Future<List<TransactionDetails>> getConfirmedTransactions() async {
    List<TransactionDetails> confirmed = [];
    final res = await config.wallet.listTransactions(true);

    for (var e in res) {
      if (e.confirmationTime != null) confirmed.add(e);
    }
    return confirmed;
  }

  Future<Balance> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final res = await config.wallet.getBalance();
    if(config.blockchain == null) {return res;}
    prefs.setInt('latestBitcoinBalance', res.total);
    return res;
  }

  Future<List<LocalUtxo>> listUnspend() async {
    final res = await config.wallet.listUnspent();
    return res;
  }

  Future<FeeRate> estimateFeeRate(int blocks) async {
    final feeRate = await config.blockchain!.estimateFee(blocks);
    return feeRate;
  }

  getInputOutPuts(TxBuilderResult txBuilderResult) async {
    final serializedPsbtTx = await txBuilderResult.psbt.jsonSerialize();
    final jsonObj = json.decode(serializedPsbtTx);
    final outputs = jsonObj["unsigned_tx"]["output"] as List;
    final inputs = jsonObj["inputs"][0]["non_witness_utxo"]["output"] as List;
    debugPrint("=========Inputs=====");
    for (var e in inputs) {
      debugPrint("amount: ${e["value"]}");
      debugPrint("script_pubkey: ${e["script_pubkey"]}");
    }
    debugPrint("=========Outputs=====");
    for (var e in outputs) {
      debugPrint("amount: ${e["value"]}");
      debugPrint("script_pubkey: ${e["script_pubkey"]}");
    }
  }

  sendBitcoin(String addressStr, FeeRate feeRate) async {
    try {
      final txBuilder = TxBuilder();
      final address = await Address.create(address: addressStr);

      final script = await address.scriptPubKey();
      final txBuilderResult = await txBuilder
          .addRecipient(script, 750)
          .feeRate(feeRate.asSatPerVb())
          .finish(config.wallet);
      getInputOutPuts(txBuilderResult);
      final aliceSbt = await config.wallet.sign(psbt: txBuilderResult.psbt);
      final tx = await aliceSbt.extractTx();
      Isolate.run(() async => {await config.blockchain!.broadcast(tx)});
    } on Exception catch (_) {
      rethrow;
    }
  }
}

class Bitcoin {
  final Wallet wallet;
  final Blockchain? blockchain;

  Bitcoin(this.wallet, this.blockchain);
}

class SendParams {
  final String address;
  final int blocks;

  SendParams(this.address, this.blocks);
}