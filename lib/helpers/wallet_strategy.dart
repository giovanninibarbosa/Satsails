import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../channels/greenwallet.dart' as greenwallet;
import '../../../helpers/networks.dart';
import '../../services/sideswap/sideswap_peg.dart';

class WalletStrategy {
  late SideswapPeg _webSocketService = SideswapPeg();
  late SideswapPegStatus _webSocketServiceStatus = SideswapPegStatus();
  late int fee;
  late String orderId;
  late String pegAddress;
  late String sendToAddr;

  Stream<dynamic> get pegMessageStream => _webSocketService.messageStream;
  Stream<dynamic> get pegMessageStreamStatus => _webSocketServiceStatus.messageStream;

  void dispose() {
    _webSocketService.close();
  }

  Future<Map<String, dynamic>> checkSideswapType(String sendingAsset, String receivingAsset, bool pegIn, int amount) async {
    const storage = FlutterSecureStorage();
    String mnemonic = await storage.read(key: 'mnemonic') ?? '';

    if (sendingAsset == "L-BTC" && receivingAsset == "BTC") {
      pegIn = false;
      Map<String, dynamic> getReceiveAddress = await greenwallet.Channel('ios_wallet').getReceiveAddress(mnemonic: mnemonic, connectionType: NetworkSecurityCase.bitcoinSS.network);
      _webSocketService.connect(
        recv_addr: getReceiveAddress["address"],
        peg_in: pegIn,
      );
      Map<String, dynamic> message = await _webSocketService.messageStream.first;
      orderId = message["result"]["order_id"];
      pegAddress = message["result"]["peg_addr"];
      // sendToAddr = await greenwallet.Channel('ios_wallet').sendToAddress(mnemonic: mnemonic, connectionType: NetworkSecurityCase.liquidSS.network, address: pegAddress, amount: amount, assetId: '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d');
      sendToAddr = "he";
    } else if (sendingAsset == 'BTC' && receivingAsset == 'L-BTC') {
      pegIn = true;
      Map<String, dynamic> getReceiveAddress = await greenwallet.Channel('ios_wallet').getReceiveAddress(mnemonic: mnemonic, connectionType: NetworkSecurityCase.liquidSS.network);
      _webSocketService.connect(
        recv_addr: getReceiveAddress["address"],
        peg_in: pegIn,
      );
      Map<String, dynamic> message = await _webSocketService.messageStream.first;
      orderId = message["result"]["order_id"];
      pegAddress = message["result"]["peg_addr"];
      sendToAddr = "he";
      // sendToAddr = await greenwallet.Channel('ios_wallet').sendToAddress(mnemonic: mnemonic, connectionType: NetworkSecurityCase.bitcoinSS.network, address: pegAddress, amount: amount);
    }
    return {
      "order_id": orderId,
      "peg_addr": pegAddress,
      "txid": sendToAddr,
    };
  }

  //
  Stream <dynamic> checkPegStatus(String orderId, bool pegIn) {
    _webSocketServiceStatus.connect(
      orderId: orderId,
      pegIn: pegIn,
    );
     return _webSocketServiceStatus.messageStream;
  }

//   Subscribe to price stream and return the price to the user on button click of convert
//   on click start conversion and check for swap done
//   Before swap is done need to upload utxos to the server of asset to be sent

// For transactions you need to have a checkbox of "i want to convert dollars if needed" where a sideswap transfer from usd to l-btc is done
// if the user has l-btc and wants to send btc or vice versa you will use sideswap to convert the asset.
// After asset is converted in sufficient amount you will use the wallet to send the asset
// for lightening addr you will use boltz api to convert btc and lbtc to lightening

// ----
}