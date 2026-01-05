import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Card(
              margin: EdgeInsets.all(AppDimensions.marginMedium),
              elevation: AppDimensions.cardElevation4,
              color: AppColors.backgroundWhite,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),
                    Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.emailClientId,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        TextField(
                          onChanged: authController.setEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppColors.textBlack),
                          decoration: InputDecoration(
                            hintText: AppStrings.enterEmail,
                            hintStyle: const TextStyle(
                              color: AppColors.textGreyLight,
                            ),
                            filled: true,
                            labelStyle:  TextStyle(
                              color: AppColors.textBlack,
                            ),
                            fillColor: AppColors.backgroundWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: BorderSide(
                                color: authController.emailError.value.isNotEmpty
                                    ? AppColors.error
                                    : AppColors.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.inputPadding,
                              vertical: AppDimensions.inputPadding,
                            ),
                            errorText: authController.emailError.value.isEmpty
                                ? null
                                : authController.emailError.value,
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.clientId,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        TextField(
                          onChanged: authController.setClientId,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppColors.textBlack),
                          decoration: InputDecoration(
                            hintText: AppStrings.enterClientId,
                            hintStyle: const TextStyle(
                              color: AppColors.textGreyLight,
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: BorderSide(
                                color: authController.clientIdError.value.isNotEmpty
                                    ? AppColors.error
                                    : AppColors.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.inputPadding,
                              vertical: AppDimensions.inputPadding,
                            ),
                            errorText: authController.clientIdError.value.isEmpty
                                ? null
                                : authController.clientIdError.value,
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.password,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        TextField(
                          onChanged: authController.setPassword,
                          obscureText: !authController.passwordVisible.value,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => authController.login(),
                          style: const TextStyle(color: AppColors.textBlack),
                          decoration: InputDecoration(
                            hintText: AppStrings.enterPassword,
                            hintStyle: const TextStyle(
                              color: AppColors.textGreyLight,
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: BorderSide(
                                color: authController.passwordError.value.isNotEmpty
                                    ? AppColors.error
                                    : AppColors.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.inputPadding,
                              vertical: AppDimensions.inputPadding,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                authController.passwordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textGrey,
                              ),
                              onPressed: authController.togglePasswordVisibility,
                            ),
                            errorText: authController.passwordError.value.isEmpty
                                ? null
                                : authController.passwordError.value,
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    Obx(() {
                      if (authController.error.value != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
                          child: Container(
                            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              border: Border.all(
                                color: AppColors.error,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppDimensions.spacingSmall),
                                Expanded(
                                  child: Text(
                                    authController.error.value!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authController.isLoading.value ? null : authController.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue,
                            foregroundColor: AppColors.textWhite,
                            disabledBackgroundColor: AppColors.buttonGrey,
                            minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLarge),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingMedium,
                              vertical: AppDimensions.paddingMedium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                            ),
                            elevation: 0,
                          ),
                          child: authController.isLoading.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textWhite,
                                    ),
                                  ),
                                )
                              : const Text(
                                  AppStrings.login,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLogo() {
    return Container(
      width: AppDimensions.logoSize,
      height: AppDimensions.logoSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.logoBlue,
            AppColors.logoGreen,
            AppColors.logoBlueDark,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppDimensions.logoInnerCircle1,
            height: AppDimensions.logoInnerCircle1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          Container(
            width: AppDimensions.logoInnerCircle2,
            height: AppDimensions.logoInnerCircle2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          const Icon(
            Icons.graphic_eq,
            size: AppDimensions.logoIconSize,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
