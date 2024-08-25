import 'package:Satsails/screens/shared/delete_wallet_modal.dart';
import 'package:Satsails/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Satsails/providers/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final sendToSeed = StateProvider<bool>((ref) => false);

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Settings'.i18n(ref), style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBlockExplorerSection(context, ref),
            _buildDivider(),
            _buildSupportSection(ref),
            _buildDivider(),
            _buildClaimBoltzTransactionsSection(context, ref),
            _buildDivider(),
            _buildSeedSection(context, ref),
            _buildDivider(),
            _buildLanguageSection(ref, context),
            _buildDivider(),
            _buildAffiliatesRedirectionSection(context, ref),
            _buildDivider(),
            DeleteWalletSection(ref: ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAffiliatesRedirectionSection(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.monetization_on, color: Colors.white),
      title: Text('Affiliates Section'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: Text('Start earning money'.i18n(ref), style: TextStyle(color: Colors.grey)),
      onTap: () {
        Navigator.pushNamed(context, '/start_affiliate');
      },
    );
  }

  Widget _buildBlockExplorerSection(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Clarity.block_solid, color: Colors.white),
      title: Text('Search the blockchain'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: const Text('mempool.com', style: TextStyle(color: Colors.grey)),
      onTap: () {
        Navigator.pushNamed(context, '/search_modal');
      },
    );
  }

  Widget _buildLanguageSection(WidgetRef ref, BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListTile(
      leading: const Icon(Icons.language, color: Colors.white),
      title: Text('Language'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: Text(settings.language.toUpperCase(), style: const TextStyle(color: Colors.grey)),
      onTap: () {
        showModalBottomSheet(
          backgroundColor: Colors.black,
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Flag(Flags.portugal),
                  title: Text('Portuguese'.i18n(ref), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    settingsNotifier.setLanguage('pt');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Flag(Flags.united_states_of_america),
                  title: Text('English'.i18n(ref), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    settingsNotifier.setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSeedSection(BuildContext context, WidgetRef ref) {
    final walletBackedUp = ref.watch(settingsProvider).backup;
    return ListTile(
      leading: const Icon(Icons.currency_bitcoin, color: Colors.white),
      title: Text('View Seed Words'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: Text('Write them down and keep them safe!'.i18n(ref), style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: () {
        ref.read(sendToSeed.notifier).state = true;
        walletBackedUp ? Navigator.pushNamed(context, '/open_pin') : Navigator.pushNamed(context, '/seed_words');
      },
    );
  }

  Widget _buildSupportSection(WidgetRef ref) {
    final Uri url = Uri.parse('https://t.me/deepcodevalue');

    return ListTile(
      leading: const Icon(LineAwesome.telegram, color: Colors.white),
      title:  Text('Help & Support & Bug reporting'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: Text('Chat with us on Telegram!'.i18n(ref), style: const TextStyle(color: Colors.grey)),
      onTap: () {
        launchUrl(url);
      },
    );
  }

  Widget _buildClaimBoltzTransactionsSection(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.flash_on, color: Colors.white),
      title: Text('Lightning Transactions'.i18n(ref), style: const TextStyle(color: Colors.white)),
      subtitle: Text('Claim your Boltz transactions'.i18n(ref), style: const TextStyle(color: Colors.grey)),
      onTap: () {
        Navigator.pushNamed(context, '/claim_boltz_transactions');
      },
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[300],
    );
  }
}
