import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _contactEmail = 'chillingzworldwide@gmail.com';
  static const String _sourceUrl = 'https://chillingz-dca92.web.app/privacy-policy';

  static const List<_PolicySectionData> _sections = [
    _PolicySectionData(
      title: '1. Who we are',
      body:
          'Chillingz ("Chillingz", "we", "us", "our") is operated by Joseph Lamptey trading as Chillingz, based in London, United Kingdom, who is the data controller for the personal data described in this policy. If you have any questions about this policy or your data, contact us at $_contactEmail.',
    ),
    _PolicySectionData(
      title: '2. The data we collect',
      body:
          'Depending on how you use Chillingz, we may collect:\n\nInformation you give us',
      bullets: [
        'Contact details - such as your name and email address (for example, when you join the waitlist or create an account).',
        'Preferences - your selected moods, interests, and any settings you choose (for example, the interest words that shape your recommendations).',
        'Communications - messages you send us and your responses to surveys or feedback requests.',
      ],
      trailingBody: 'Information we collect automatically',
      trailingBullets: [
        'Location data - your approximate or precise location, where you allow it, so we can suggest activities near you. You control this through your device permissions and can turn it off at any time.',
        'Usage and device data - how you interact with the app or website, device and browser type, app version, and similar technical information.',
        'Cookies and similar technologies.',
      ],
      closingBody:
          'Information from third parties\n\nAnalytics and advertising partners (for example, if you arrive via a link on Instagram or TikTok), and affiliate and booking partners, who may tell us that a referral or booking you started through Chillingz was completed, so we can be credited.\n\nWe do not intentionally collect special category data (such as health or religious information). Please don\'t send it to us.',
    ),
    _PolicySectionData(
      title: '3. How and why we use your data, and our lawful basis',
      body:
          'Under UK data protection law we must have a "lawful basis" for using your data. We rely on the following:',
      bullets: [
        'Creating and running your account, and providing the core discovery and recommendation service — Performance of a contract with you.',
        'Showing you activities relevant to your mood, interests, and location — Legitimate interests (giving you a useful, personalised service) and, for location, your consent via device permissions.',
        'Sending you marketing emails, launch updates, and our newsletter — Your consent.',
        'Measuring and improving the app, fixing problems, and keeping it secure — Legitimate interests (running and improving our service).',
        'Tracking referrals and bookings so partners credit us commission — Legitimate interests (operating our business).',
        'Meeting legal and regulatory obligations — Legal obligation.',
      ],
      trailingBody:
          'Where we rely on legitimate interests, we have balanced those interests against your rights, and you can object at any time (see section 8). Where we rely on consent, you can withdraw it at any time without affecting earlier processing.',
    ),
    _PolicySectionData(
      title: '4. Who we share your data with',
      body: 'We do not sell your personal data. We share it only with:',
      bullets: [
        'Service providers (processors) who help us run Chillingz under contract and only on our instructions. These currently include: our email platform MailerLite, our newsletter platform Substack, our hosting and website tools (Framer / GoDaddy), analytics providers, and Google services (such as maps and form tools).',
        'Affiliate and booking partners (for example Awin and Fever) - when you click through to them, so your referral can be tracked and credited. Once you\'re on their platform, their own privacy policy applies.',
        'App stores (Apple, Google) if you download the app.',
        'Others where required by law, to enforce our Terms, or in connection with a sale or restructure of the Chillingz business (with your rights protected).',
      ],
    ),
    _PolicySectionData(
      title: '5. International transfers',
      body:
          'Some of our providers are based outside the UK. Where your data is transferred abroad, we make sure it is protected by an approved safeguard - such as an adequacy decision, the UK\'s International Data Transfer Agreement (IDTA) or Addendum, or another lawful mechanism.',
    ),
    _PolicySectionData(
      title: '6. How long we keep your data',
      body: 'We keep your data only as long as we need it:',
      bullets: [
        'Account and preference data - while your account is active, and for up to 6 months after you close your account.',
        'Waitlist and marketing data - until you unsubscribe or ask us to remove it.',
        'Analytics and technical data - for a limited period, often in aggregated or de-identified form.',
      ],
      trailingBody:
          'When we no longer need your data, we delete or anonymise it.',
    ),
    _PolicySectionData(
      title: '7. Cookies and similar technologies',
      body:
          'Our website and app use cookies and similar technologies to make the service work, remember your preferences, measure usage, and with your consent, support affiliate tracking and marketing.\n\nNon-essential cookies (such as analytics and advertising) are only set with your consent, in line with UK privacy rules (PECR). You can manage your choices through our cookie banner and your browser or device settings. Note that some affiliate tracking may rely on cookies that do not always persist across links between apps, which can affect whether a referral is recorded.',
    ),
    _PolicySectionData(
      title: '8. Your rights',
      body: 'Under UK data protection law you have the right to:',
      bullets: [
        'Access the personal data we hold about you.',
        'Ask us to correct inaccurate or incomplete data.',
        'Ask us to erase your data in certain circumstances.',
        'Restrict or object to how we use your data, including objecting to direct marketing at any time.',
        'Request portability of data you gave us, in a reusable format.',
        'Withdraw consent at any time where we rely on it.',
      ],
      trailingBody:
          'To exercise any of these, contact us at $_contactEmail. We\'ll respond within one month. There\'s usually no charge.\n\nIf you\'re unhappy with how we handle your data, you can complain to the UK\'s supervisory authority, the Information Commissioner\'s Office (ICO) at ico.org.uk - though we\'d appreciate the chance to put things right first.',
    ),
    _PolicySectionData(
      title: '9. How we protect your data',
      body:
          'We use appropriate technical and organisational measures to keep your data secure. No method of transmission or storage is completely secure, but we take reasonable steps to protect it and to respond appropriately if something goes wrong.',
    ),
    _PolicySectionData(
      title: '10. Children',
      body:
          'Chillingz is not intended for anyone under 18. We do not knowingly collect data from children. If you believe a child has given us their data, contact us and we\'ll delete it.',
    ),
    _PolicySectionData(
      title: '11. Changes to this policy',
      body:
          'We may update this policy from time to time. The "Last updated" date shows when it last changed, and we\'ll take reasonable steps to tell you about significant changes.',
    ),
    _PolicySectionData(
      title: '12. Contact us',
      body: 'Questions, requests, or concerns about your data? Contact us at $_contactEmail.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: AppStrings.privacyPolicy),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.rs(18, min: 16, max: 24),
            context.rs(12, min: 10, max: 16),
            context.rs(18, min: 16, max: 24),
            context.rs(28, min: 24, max: 34),
          ),
          children: [
            Text(
              'Privacy Policy for Chillingz',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: context.rs(24, min: 22, max: 28),
                fontWeight: FontWeight.w700,
              ),
            ),
            context.rs(8, min: 8, max: 10).vSpace,
            Text(
              'Effective date: August 24, 2026',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: context.rs(13.5, min: 13, max: 14.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            context.rs(14, min: 12, max: 16).vSpace,
            Text(
              'This Privacy Policy explains how Chillingz collects, uses, and protects your personal data when you use our app or website, and your rights under UK data protection law (the UK GDPR and the Data Protection Act 2018). Please read it alongside our Terms & Conditions.',
              style: _bodyStyle(context),
            ),
            context.rs(8, min: 8, max: 10).vSpace,
            Text(
              'Questions or requests: $_contactEmail',
              style: _bodyStyle(context).copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            context.rs(18, min: 16, max: 22).vSpace,
            ..._sections.map((section) => _PolicySection(section: section)),
            context.rs(8, min: 8, max: 12).vSpace,
            Text(
              'Source: $_sourceUrl',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: context.rs(12, min: 11.5, max: 12.5),
              ),
            ),
            context.rs(4, min: 4, max: 6).vSpace,
            Text(
              'Last updated: August 24, 2026',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: context.rs(12, min: 11.5, max: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _bodyStyle(BuildContext context) {
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: context.rs(14.5, min: 14, max: 15.5),
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(14, min: 12, max: 16)),
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 18)),
      decoration: BoxDecoration(
        color: AppColors.settingsTileBackground,
        borderRadius: BorderRadius.circular(context.rs(14, min: 12, max: 16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.rs(17, min: 16, max: 18),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (section.body != null) ...[
            context.rs(8, min: 7, max: 9).vSpace,
            Text(section.body!, style: PrivacyPolicyScreen._bodyStyle(context)),
          ],
          if (section.bullets.isNotEmpty) ...[
            context.rs(10, min: 9, max: 12).vSpace,
            ..._buildBullets(context, section.bullets),
          ],
          if (section.trailingBody != null) ...[
            context.rs(8, min: 7, max: 9).vSpace,
            Text(
              section.trailingBody!,
              style: PrivacyPolicyScreen._bodyStyle(context),
            ),
          ],
          if (section.trailingBullets.isNotEmpty) ...[
            context.rs(10, min: 9, max: 12).vSpace,
            ..._buildBullets(context, section.trailingBullets),
          ],
          if (section.closingBody != null) ...[
            context.rs(8, min: 7, max: 9).vSpace,
            Text(
              section.closingBody!,
              style: PrivacyPolicyScreen._bodyStyle(context),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBullets(BuildContext context, List<String> bullets) {
    return bullets
        .map(
          (bullet) => Padding(
            padding: EdgeInsets.only(bottom: context.rs(7, min: 6, max: 8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '-',
                  style: PrivacyPolicyScreen._bodyStyle(context).copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                context.rs(8, min: 7, max: 9).hSpace,
                Expanded(
                  child: Text(
                    bullet,
                    style: PrivacyPolicyScreen._bodyStyle(context),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.title,
    this.body,
    this.bullets = const [],
    this.trailingBody,
    this.trailingBullets = const [],
    this.closingBody,
  });

  final String title;
  final String? body;
  final List<String> bullets;
  final String? trailingBody;
  final List<String> trailingBullets;
  final String? closingBody;
}
