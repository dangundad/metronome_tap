import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class GuidePage extends GetView<dynamic> {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('guide'.tr),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.surface,
                cs.primary.withValues(alpha: 0.05),
                cs.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            children: [
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'guide_title'.tr,
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              _GuideCard(
                title: 'guide_tip_1_title'.tr,
                description: 'guide_tip_1_desc'.tr,
                icon: Icons.timer,
                cs: cs,
              ),
              SizedBox(height: 10.h),
              _GuideCard(
                title: 'guide_tip_2_title'.tr,
                description: 'guide_tip_2_desc'.tr,
                icon: Icons.music_note_rounded,
                cs: cs,
              ),
              SizedBox(height: 10.h),
              _GuideCard(
                title: 'guide_tip_3_title'.tr,
                description: 'guide_tip_3_desc'.tr,
                icon: Icons.settings_rounded,
                cs: cs,
              ),
              SizedBox(height: 10.h),
              _GuideCard(
                title: 'guide_tip_4_title'.tr,
                description: 'guide_tip_4_desc'.tr,
                icon: Icons.bar_chart_rounded,
                cs: cs,
              ),
              SizedBox(height: 16.h),
              Text(
                'guide_footer'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final ColorScheme cs;

  const _GuideCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
