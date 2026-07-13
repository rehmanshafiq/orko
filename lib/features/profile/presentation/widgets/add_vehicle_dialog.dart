import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_state.dart';

/// Sentinel dropdown value for the "Other (add custom)" option.
const int _kOther = -1;

/// Add-vehicle dialog. Make/model dropdowns are populated from the vehicle
/// APIs; submitting calls `add-vehicle` and refreshes the user's vehicle list.
class AddVehicleDialog extends StatefulWidget {
  const AddVehicleDialog({super.key});

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rfidController = TextEditingController();

  // Custom make / model inputs.
  final TextEditingController _customMakeController = TextEditingController();
  final TextEditingController _customModelNameController =
      TextEditingController();
  final TextEditingController _connectorController = TextEditingController();
  final TextEditingController _batteryController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  int? _selectedMakeId;
  int? _selectedModelId;

  /// Whether the inline "add custom make/model" forms are showing (i.e. the
  /// user picked "Other" and hasn't created it yet).
  bool _showCustomMakeForm = false;
  bool _showCustomModelForm = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<VehicleCubit>();
    // Reset any stale models and ensure makes are loaded for the dropdown.
    cubit.resetModels();
    if (cubit.state.makesStatus != VehicleStatus.success) {
      cubit.loadMakes();
    }
  }

  @override
  void dispose() {
    _rfidController.dispose();
    _customMakeController.dispose();
    _customModelNameController.dispose();
    _connectorController.dispose();
    _batteryController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _onMakeChanged(int? makeId) {
    if (makeId == null) return;
    // "Other" → reveal the custom-make text input instead of selecting a make.
    if (makeId == _kOther) {
      setState(() {
        _showCustomMakeForm = true;
        _selectedMakeId = null;
        _selectedModelId = null;
        _showCustomModelForm = false;
      });
      context.read<VehicleCubit>().resetModels();
      return;
    }
    if (makeId == _selectedMakeId && !_showCustomMakeForm) return;
    setState(() {
      _selectedMakeId = makeId;
      _selectedModelId = null;
      _showCustomMakeForm = false;
      _showCustomModelForm = false;
    });
    context.read<VehicleCubit>().loadModels(makeId);
  }

  void _onModelChanged(int? modelId) {
    if (modelId == null) return;
    if (modelId == _kOther) {
      setState(() {
        _showCustomModelForm = true;
        _selectedModelId = null;
      });
      return;
    }
    setState(() {
      _selectedModelId = modelId;
      _showCustomModelForm = false;
    });
  }

  /// Creates the custom make, then selects it so the user can add a model.
  Future<void> _onCreateCustomMake() async {
    final name = _customMakeController.text.trim();
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Enter a make name.');
      return;
    }
    final cubit = context.read<VehicleCubit>();
    final result = await cubit.createCustomMake(name);
    if (!mounted) return;
    if (result.success && result.make != null) {
      setState(() {
        _selectedMakeId = result.make!.id;
        _showCustomMakeForm = false;
        // A brand-new make has no models yet — force the custom-model form.
        _selectedModelId = null;
        _showCustomModelForm = false;
      });
      cubit.resetModels();
    } else {
      showErrorSnackBar(context, result.message);
    }
  }

  /// Creates the custom model under the selected make, then selects it.
  Future<void> _onCreateCustomModel() async {
    final makeId = _selectedMakeId;
    if (makeId == null) {
      showErrorSnackBar(context, 'Select or create a make first.');
      return;
    }
    final name = _customModelNameController.text.trim();
    final connector = _connectorController.text.trim();
    final battery = double.tryParse(_batteryController.text.trim());
    final mileage = int.tryParse(_mileageController.text.trim());
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Enter a model name.');
      return;
    }
    if (connector.isEmpty) {
      showErrorSnackBar(context, 'Enter the connector type (e.g. CCS).');
      return;
    }
    if (battery == null || battery <= 0) {
      showErrorSnackBar(context, 'Enter a valid battery capacity (kWh).');
      return;
    }
    if (mileage == null || mileage <= 0) {
      showErrorSnackBar(context, 'Enter a valid mileage (km).');
      return;
    }
    final cubit = context.read<VehicleCubit>();
    final result = await cubit.createCustomModel(
      mdMake: makeId,
      name: name,
      connectorType: connector,
      batteryCapacity: battery,
      mileage: mileage,
    );
    if (!mounted) return;
    if (result.success && result.model != null) {
      setState(() {
        _selectedModelId = result.model!.id;
        _showCustomModelForm = false;
      });
    } else {
      showErrorSnackBar(context, result.message);
    }
  }

  Future<void> _submit() async {
    // Custom make/model must be created (not just typed) before submitting.
    if (_showCustomMakeForm || _selectedMakeId == null) {
      showErrorSnackBar(
          context, 'Please select a make, or add your custom make first.');
      return;
    }
    if (_showCustomModelForm || _selectedModelId == null) {
      showErrorSnackBar(
          context, 'Please select a model, or add your custom model first.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<VehicleCubit>();
    final result = await cubit.addVehicle(
      mdMake: _selectedMakeId!,
      mdModel: _selectedModelId!,
      // Year is no longer collected in the form; the API still requires a
      // value, so default it to the current year.
      year: DateTime.now().year.toString(),
      // Registration number (sent to the API as `vehicle_reg`) is now required.
      vehicleRfid: _rfidController.text.trim(),
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      showErrorSnackBar(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: ui.cardBackground,
          insetPadding:
              EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: AppUtils.all18Padding,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: ui.brandPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car_outlined,
                            color: ui.brandPrimary,
                            size: 22.r,
                          ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: AppText(
                            'Add New Vehicle',
                            color: ui.textPrimary,
                            fontSize: FontSizes.font18Sp,
                            fontWeight: FontWeights.weight700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.close_rounded,
                            color: ui.textSecondary,
                            size: 22.r,
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    AppText(
                      'Select your vehicle details below.',
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    18.verticalSpace,
                    _MakeField(
                      state: state,
                      selectedMakeId: _selectedMakeId,
                      showCustomMakeForm: _showCustomMakeForm,
                      onChanged: _onMakeChanged,
                    ),
                    if (_showCustomMakeForm) ...[
                      10.verticalSpace,
                      _CustomMakeForm(
                        controller: _customMakeController,
                        isCreating: state.isCreatingMake,
                        onSubmit: _onCreateCustomMake,
                      ),
                    ],
                    14.verticalSpace,
                    _ModelField(
                      state: state,
                      selectedMakeId: _selectedMakeId,
                      selectedModelId: _selectedModelId,
                      showCustomMakeForm: _showCustomMakeForm,
                      showCustomModelForm: _showCustomModelForm,
                      onChanged: _onModelChanged,
                    ),
                    if (_showCustomModelForm) ...[
                      10.verticalSpace,
                      _CustomModelForm(
                        nameController: _customModelNameController,
                        connectorController: _connectorController,
                        batteryController: _batteryController,
                        mileageController: _mileageController,
                        isCreating: state.isCreatingModel,
                        onSubmit: _onCreateCustomModel,
                      ),
                    ],
                    14.verticalSpace,
                    _RegistrationField(controller: _rfidController),
                    22.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButtonWidget(
                            text: 'Cancel',
                            onPress: state.isSubmitting
                                ? () {}
                                : () => Navigator.of(context).pop(),
                            buttonWidth: double.infinity,
                            buttonHeight: 38.h,
                            cornerRadius: 24.r,
                            buttonColor: ui.chipInactiveBg,
                            strokeColor: ui.borderSubtle,
                            textColor: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: _GradientActionButton(
                            label: 'Add Vehicle',
                            loading: state.isSubmitting,
                            onTap: _submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The shared "Other (add custom)" dropdown option.
DropdownMenuItem<int> _otherDropdownItem(AppUiColors ui) {
  return DropdownMenuItem<int>(
    value: _kOther,
    child: Row(
      children: [
        Icon(Icons.add_circle_outline_rounded,
            size: 18.r, color: ui.brandPrimary),
        8.horizontalSpace,
        AppText(
          'Other (add custom)',
          color: ui.brandPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight600,
        ),
      ],
    ),
  );
}

/// Make dropdown, with a failure/retry state and the "Other" custom option.
class _MakeField extends StatelessWidget {
  const _MakeField({
    required this.state,
    required this.selectedMakeId,
    required this.showCustomMakeForm,
    required this.onChanged,
  });

  final VehicleState state;
  final int? selectedMakeId;
  final bool showCustomMakeForm;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    if (state.makesStatus == VehicleStatus.failure) {
      return _DropdownErrorField(
        ui: ui,
        label: 'Make',
        message: state.makesError ?? 'Could not load makes.',
        onRetry: () => context.read<VehicleCubit>().loadMakes(),
      );
    }
    return _VehicleDropdownField<int>(
      // Rebuild when the selection changes programmatically (e.g. after
      // creating a custom make), so the field reflects the new value.
      key: ValueKey('make_${showCustomMakeForm ? 'other' : selectedMakeId}'),
      ui: ui,
      label: 'Vehicle',
      hintText: state.makesStatus == VehicleStatus.loading
          ? 'Loading makes...'
          : 'Select Vehicle',
      value: showCustomMakeForm ? _kOther : selectedMakeId,
      isLoading: state.makesStatus == VehicleStatus.loading,
      enabled: state.makesStatus == VehicleStatus.success,
      items: [
        for (final make in state.makes)
          DropdownMenuItem<int>(
            value: make.id,
            child: Row(
              children: [
                _MakeLogo(url: make.logo),
                8.horizontalSpace,
                Flexible(
                  child: AppText(
                    make.name,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        _otherDropdownItem(ui),
      ],
      validator: (v) => (v == null || v == _kOther) && !showCustomMakeForm
          ? 'Make is required'
          : null,
      onChanged: onChanged,
    );
  }
}

/// Model dropdown for the selected make, with the "Other" custom option.
class _ModelField extends StatelessWidget {
  const _ModelField({
    required this.state,
    required this.selectedMakeId,
    required this.selectedModelId,
    required this.showCustomMakeForm,
    required this.showCustomModelForm,
    required this.onChanged,
  });

  final VehicleState state;
  final int? selectedMakeId;
  final int? selectedModelId;
  final bool showCustomMakeForm;
  final bool showCustomModelForm;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    if (selectedMakeId != null &&
        state.modelsStatus == VehicleStatus.failure) {
      return _DropdownErrorField(
        ui: ui,
        label: 'Model',
        message: state.modelsError ?? 'Could not load models.',
        onRetry: () => context.read<VehicleCubit>().loadModels(selectedMakeId!),
      );
    }
    final hasModels = state.models.isNotEmpty;
    final loading = state.modelsStatus == VehicleStatus.loading;
    // A make must be picked/created first; once it is, "Other" is always
    // offered (a brand-new custom make legitimately has no models yet).
    final makeReady = selectedMakeId != null && !showCustomMakeForm;
    return _VehicleDropdownField<int>(
      key: ValueKey(
          'model_${showCustomModelForm ? 'other' : selectedModelId}_$makeReady'),
      ui: ui,
      label: 'Model',
      hintText: !makeReady
          ? 'Select Model'
          : loading
              ? 'Loading models...'
              : (hasModels ? 'Select Model' : 'Add a custom model'),
      value: showCustomModelForm ? _kOther : selectedModelId,
      isLoading: loading,
      enabled: makeReady && !loading,
      items: [
        for (final model in state.models)
          DropdownMenuItem<int>(
            value: model.id,
            child: AppText(
              model.name,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        _otherDropdownItem(ui),
      ],
      validator: (v) => (v == null || v == _kOther) && !showCustomModelForm
          ? 'Model is required'
          : null,
      onChanged: onChanged,
    );
  }
}

/// Inline "add custom make" form shown when the user picks "Other".
class _CustomMakeForm extends StatelessWidget {
  const _CustomMakeForm({
    required this.controller,
    required this.isCreating,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isCreating;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.inputFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledTextField(
            label: 'Make Name',
            controller: controller,
            hint: 'e.g. Tesla',
            capitalization: TextCapitalization.words,
          ),
          12.verticalSpace,
          _GradientActionButton(
            label: 'Add Make',
            loading: isCreating,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Inline "add custom model" form shown when the user picks "Other".
class _CustomModelForm extends StatelessWidget {
  const _CustomModelForm({
    required this.nameController,
    required this.connectorController,
    required this.batteryController,
    required this.mileageController,
    required this.isCreating,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController connectorController;
  final TextEditingController batteryController;
  final TextEditingController mileageController;
  final bool isCreating;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.inputFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledTextField(
            label: 'Model Name',
            controller: nameController,
            hint: 'e.g. Model 3',
            capitalization: TextCapitalization.words,
          ),
          12.verticalSpace,
          _LabeledTextField(
            label: 'Connector Type',
            controller: connectorController,
            hint: 'e.g. CCS',
            capitalization: TextCapitalization.characters,
          ),
          12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledTextField(
                  label: 'Battery (kWh)',
                  controller: batteryController,
                  hint: 'e.g. 60',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: _LabeledTextField(
                  label: 'Mileage (km)',
                  controller: mileageController,
                  hint: 'e.g. 200',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          12.verticalSpace,
          _GradientActionButton(
            label: 'Add Model',
            loading: isCreating,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// A labelled text input styled like the registration field, used by the
/// custom make/model forms (plain [TextField] — validated manually).
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: inputFormatters,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: ui.cardBackground,
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              fontFamily: AppFonts.lexend,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.brandPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small gradient action button (with in-flight spinner) used for the custom
/// forms and the dialog's submit action.
class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 38.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryDarkColor,
              AppColors.primaryDarkButtonColor,
            ],
          ),
        ),
        child: SizedBox(
          width: 18.r,
          height: 18.r,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.whiteColor,
          ),
        ),
      );
    }
    return PrimaryButtonWidget(
      text: label,
      onPress: onTap,
      buttonWidth: double.infinity,
      buttonHeight: 38.h,
      cornerRadius: 24.r,
      gradientColors: const [
        AppColors.primaryDarkColor,
        AppColors.primaryDarkButtonColor,
      ],
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

/// The required vehicle-registration-number form field.
class _RegistrationField extends StatelessWidget {
  const _RegistrationField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Vehicle Registration Number',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'Registration number is required';
            if (value.length < 3) {
              return 'Enter a valid registration number';
            }
            return null;
          },
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: ui.inputFill,
            isDense: true,
            hintText: 'e.g. ABC-123',
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              fontFamily: AppFonts.lexend,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.brandPrimary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            errorStyle: TextStyle(
              color: AppColors.redColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small brand-logo thumbnail shown beside a make in the dropdown. Falls back
/// to a neutral car icon when the URL is empty or fails to load.
class _MakeLogo extends StatelessWidget {
  const _MakeLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final size = 24.r;

    Widget fallback() => Icon(
          Icons.directions_car_outlined,
          size: 18.r,
          color: AppColors.whiteColor,
        );

    return SizedBox(
      width: size,
      height: size,
      child: url.isEmpty
          ? fallback()
          : Image.network(
              url,
              fit: BoxFit.contain,
              // Render the brand logo as a white silhouette.
              color: ui.textSecondary,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => fallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback(),
            ),
    );
  }
}

/// A labelled dropdown matching the dialog's field styling.
class _VehicleDropdownField<T> extends StatelessWidget {
  const _VehicleDropdownField({
    super.key,
    required this.ui,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.isLoading = false,
  });

  final AppUiColors ui;
  final String label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          // Cap the popup height so long lists (e.g. makes) scroll instead of
          // stretching to the full screen height.
          menuMaxHeight: 260.h,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          icon: isLoading
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ui.textSecondary,
                  ),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? ui.textSecondary : ui.textMuted,
                  size: 22.r,
                ),
          dropdownColor: ui.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          hint: AppText(
            hintText,
            color: AppColors.hintColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          items: items,
          decoration: InputDecoration(
            filled: true,
            fillColor: ui.inputFill,
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.brandPrimary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            errorStyle: TextStyle(
              color: AppColors.redColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline error + retry shown in place of a dropdown when its data fails.
class _DropdownErrorField extends StatelessWidget {
  const _DropdownErrorField({
    required this.ui,
    required this.label,
    required this.message,
    required this.onRetry,
  });

  final AppUiColors ui;
  final String label;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: ui.inputFill,
            borderRadius: BorderRadius.circular(12.r),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.redColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  message,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              8.horizontalSpace,
              GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: AppText(
                  'Retry',
                  color: ui.brandPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
