import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_app_bar.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String _contactEmail = 'chillingzworldwide@gmail.com';
  static const String _sourceUrl =
      'https://chillingz-dca92.web.app/terms-and-conditions';

  static const List<_TermsSectionData> _sections = [
    _TermsSectionData(
      title: '1. Who we are',
      body:
          'Chillingz ("Chillingz", "we", "us", "our") is a mood, interest, and location-based activity discovery service operated by Joseph Lamptey trading as Chillingz, based in London, United Kingdom. You can contact us at $_contactEmail. In these Terms, "you" and "your" mean the person accessing or using the service.',
    ),
    _TermsSectionData(
      title: '2. What Chillingz does (and does not do)',
      body:
          'Chillingz helps you discover activities, venues, events, and experiences based on your mood, interests, and location. We surface recommendations and, where available, link you through to third parties (such as venues, event organisers, and booking platforms) where you can book, buy tickets, or find out more.\n\nChillingz is a discovery and referral platform. We are not the provider, organiser, or seller of the activities, events, or venues shown in the app.',
      bullets: [
        'We do not own, operate, or control any venue, event, or experience listed.',
        'We do not sell tickets, take bookings, or process payments for activities on behalf of third parties.',
        'We do not act as agent for you or for any venue or organiser.',
      ],
      trailingBody:
          'Any booking, purchase, or transaction you make is a contract directly between you and the relevant third party, on that third party\'s own terms. We are not a party to it and are not responsible for it (see sections 6 and 10).',
    ),
    _TermsSectionData(
      title: '3. Eligibility',
      body:
          'You must be at least 18 years old to use Chillingz. By using the service, you confirm that you meet this requirement. Some listed venues, events, or experiences may have their own age restrictions (for example, licensed premises or nightlife), and it is your responsibility to check and comply with them. Chillingz is not responsible for you the user booking an experience if you don\'t comply with age requirements.',
    ),
    _TermsSectionData(
      title: '4. Your account',
      body:
          'You must create an account in order for you to use Chillingz. You agree to:',
      bullets: [
        'Provide accurate and complete information and keep it up to date.',
        'Keep your login details confidential and not share them.',
        'Take responsibility for all activity under your account.',
      ],
      trailingBody:
          'You must let us know promptly at $_contactEmail if you believe your account has been accessed without your permission. We may suspend or close accounts as described in section 13.',
    ),
    _TermsSectionData(
      title: '5. Using Chillingz responsibly',
      body: 'You agree not to:',
      bullets: [
        'Use the service for any unlawful, fraudulent, or harmful purpose.',
        'Copy, scrape, harvest, or extract data or content from the app or website, or use it to build or train any competing product, database, or model.',
        'Attempt to gain unauthorised access to, interfere with, or disrupt the service or its underlying systems.',
        'Upload or transmit anything that is unlawful, defamatory, abusive, misleading, or infringes anyone\'s rights.',
        'Misuse referral or affiliate links, or attempt to manipulate recommendations, listings, or any promotions.',
      ],
      trailingBody:
          'We may remove content, restrict features, or suspend access if we reasonably believe you have breached these Terms.',
    ),
    _TermsSectionData(
      title: '6. Third-party venues, events, and bookings',
      body:
          'Listings on Chillingz — including descriptions, images, opening hours, pricing, availability, and location details — are provided by or sourced from third parties (including venues, organisers, and data providers such as mapping services).\n\nWe take reasonable care but we do not warrant that any listing is accurate, complete, current, or available. Prices, availability, and details change frequently and outside our control. Always confirm the key details (price, timing, availability, age limits, accessibility, and any restrictions) directly with the venue or organiser before you travel, book, or pay.\n\nWhen you follow a link from Chillingz to a third party, you leave our service and are subject to that third party\'s own terms and privacy policy. Your booking or purchase is with them, not us. Any issues with a booking, ticket, refund, cancellation, quality, safety, or conduct at a venue or event are between you and that third party.',
    ),
    _TermsSectionData(
      title: '7. Affiliate relationships and how we make money',
      body:
          'Chillingz may earn commission or fees when you click certain links or complete bookings or purchases with third parties we partner with (for example, ticketing and booking platforms). This does not cost you anything extra.\n\nWe aim to recommend activities based on their relevance to your mood, interests, and location — not solely on whether we earn a commission. Some listings may be paid, boosted, or promoted placements; where required, these will be identified as such. Earning commission does not mean we endorse or guarantee any third party, and it does not change your rights against that third party.',
    ),
    _TermsSectionData(
      title: '8. Marketing and communications',
      body:
          'If you join our waitlist or sign up, you may receive emails from us (for example, launch updates, recommendations, or our newsletter). You can unsubscribe at any time using the link in any marketing email or by contacting us. We handle your personal data as described in our Privacy Policy.',
    ),
    _TermsSectionData(
      title: '9. Intellectual property',
      body:
          'The Chillingz name, logo, app, website, design, and all content we create are owned by us or our licensors and are protected by intellectual property laws. We grant you a limited, personal, non-exclusive, non-transferable, revocable licence to use the service for your own personal, non-commercial use in line with these Terms. All other rights are reserved.\n\nThird-party names, logos, and content shown in listings belong to their respective owners.',
    ),
    _TermsSectionData(
      title: '10. Disclaimers',
      body:
          'The service is provided on an "as is" and "as available" basis. To the extent permitted by law, we do not guarantee that the service will be uninterrupted, error-free, secure, or that recommendations will suit your needs.\n\nRecommendations are suggestions only. You are responsible for your own decisions about which activities to attend and for your own safety, and for assessing the suitability, safety, and legality of any activity, venue, or event.\n\nNothing in these Terms affects your statutory rights as a consumer.',
    ),
    _TermsSectionData(
      title: '11. Our liability to you',
      body: 'Nothing in these Terms limits or excludes our liability for:',
      bullets: [
        'Death or personal injury caused by our negligence.',
        'Fraud or fraudulent misrepresentation.',
        'Any other liability that cannot be limited or excluded under the law of England and Wales.',
      ],
      trailingBody:
          'Subject to the above, and because Chillingz is a free discovery service and not a party to your transactions with third parties, we are not liable for the acts, omissions, products, services, or content of any venue, organiser, booking platform, or other third party; for any loss or damage arising from your reliance on any listing, price, or recommendation, or from any activity, event, or venue you attend; or for business losses, or for loss or damage that is not reasonably foreseeable.\n\nWhere we are found liable to you despite the above, our total liability arising out of or in connection with the service is limited to £100 (or, if you have paid us any fees in the 12 months before the claim, the greater of that amount and the fees paid).',
    ),
    _TermsSectionData(
      title: '12. Indemnity',
      body:
          'You agree to be responsible for, and to reimburse us for, any reasonable losses, costs, or claims we suffer that arise from your misuse of the service or your breach of these Terms or of any applicable law.',
    ),
    _TermsSectionData(
      title: '13. Suspension and termination',
      body:
          'You can stop using Chillingz and delete your account at any time.\n\nWe may suspend, restrict, or end your access to the service (in whole or in part) if you breach these Terms, if we reasonably suspect misuse, or if we need to for legal, security, or operational reasons. We may also change, suspend, or discontinue any part of the service at any time.\n\nYou must let us know promptly at $_contactEmail if you believe your account has been accessed without your permission.',
    ),
    _TermsSectionData(
      title: '14. Changes to these Terms',
      body:
          'We may update these Terms from time to time. If we make significant changes, we will take reasonable steps to let you know (for example, by notice in the app or by email). The "Last updated" date at the top shows when the Terms were last revised. Continuing to use the service after changes take effect means you accept the updated Terms.',
    ),
    _TermsSectionData(
      title: '15. Privacy',
      body:
          'We take your privacy seriously. How we collect and use your personal data — including your location and interest preferences — is set out in our Privacy Policy, which forms part of your agreement with us and complies with UK data protection law (UK GDPR and the Data Protection Act 2018).',
    ),
    _TermsSectionData(
      title: '16. General',
      bullets: [
        'Governing law. These Terms and any dispute arising from them are governed by the law of England and Wales, and the courts of England and Wales have non-exclusive jurisdiction.',
        'Severability. If any part of these Terms is found to be invalid or unenforceable, the rest continues to apply.',
        'No waiver. If we do not enforce a right, that is not a waiver of it.',
        'Assignment. You may not transfer your rights under these Terms. We may transfer ours to a successor of the Chillingz business, provided your rights are not adversely affected.',
        'Entire agreement. These Terms, together with our Privacy Policy, are the entire agreement between you and us regarding the service.',
      ],
    ),
    _TermsSectionData(
      title: '17. Contact and complaints',
      body:
          'If you have a question or complaint, contact us at $_contactEmail and we will do our best to help.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: AppStrings.termsConditions),
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
              'Terms and Conditions for Chillingz',
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
              'Please read these Terms carefully before using Chillingz. By downloading, accessing, or using the Chillingz app or website, you agree to be bound by these Terms. If you do not agree, please do not use the service.',
              style: _bodyStyle(context),
            ),
            context.rs(8, min: 8, max: 10).vSpace,
            Text(
              'Questions or complaints: $_contactEmail',
              style: _bodyStyle(context).copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            context.rs(18, min: 16, max: 22).vSpace,
            ..._sections.map((section) => _TermsSection(section: section)),
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.section});

  final _TermsSectionData section;

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
            Text(
              section.body!,
              style: TermsConditionsScreen._bodyStyle(context),
            ),
          ],
          if (section.bullets.isNotEmpty) ...[
            context.rs(10, min: 9, max: 12).vSpace,
            ...section.bullets.map(
              (bullet) => Padding(
                padding: EdgeInsets.only(bottom: context.rs(7, min: 6, max: 8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '-',
                      style: TermsConditionsScreen._bodyStyle(
                        context,
                      ).copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    context.rs(8, min: 7, max: 9).hSpace,
                    Expanded(
                      child: Text(
                        bullet,
                        style: TermsConditionsScreen._bodyStyle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (section.trailingBody != null) ...[
            context.rs(8, min: 7, max: 9).vSpace,
            Text(
              section.trailingBody!,
              style: TermsConditionsScreen._bodyStyle(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _TermsSectionData {
  const _TermsSectionData({
    required this.title,
    this.body,
    this.bullets = const [],
    this.trailingBody,
  });

  final String title;
  final String? body;
  final List<String> bullets;
  final String? trailingBody;
}
