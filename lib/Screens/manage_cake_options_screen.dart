import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:http/http.dart' as http;
// Assuming Constants.baseUrl and Constants.prefs exist and are configured
// Ensure you have these imports or adapt them to your project structure
import 'package:the_cakery/utils/constants.dart';

// Enum to represent the different option types for clarity
enum OptionType { topping, sponge, extra }

// Helper extension for capitalizing strings (optional but nice)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// --- Category Choices for Extras ---
const Map<String, String> extraCategoryChoices = {
  "fillings": "Filling",
  "candles": "Candle",
  "colors": "Color",
  "decorations": "Edible Decoration",
  "packaging": "Packaging",
};
// --- End Category Choices ---

class ManageCakeOptionsScreen extends StatefulWidget {
  const ManageCakeOptionsScreen({super.key});

  @override
  State<ManageCakeOptionsScreen> createState() =>
      _ManageCakeOptionsScreenState();
}

class _ManageCakeOptionsScreenState extends State<ManageCakeOptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data holders
  List<Map<String, dynamic>> _toppings = [];
  List<Map<String, dynamic>> _sponges = [];
  List<Map<String, dynamic>> _extras = [];

  // Loading states for fetching data
  bool _isLoadingToppings = true;
  bool _isLoadingSponges = true;
  bool _isLoadingExtras = true;
  // Loading state for Add/Edit dialog is managed locally within the dialog's StatefulBuilder

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial data for all tabs
    _fetchDataForTab(0);
    _fetchDataForTab(1);
    _fetchDataForTab(2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _fetchDataForTab(int index, {bool forceRefresh = true}) async {
    if (!mounted) return;

    final String? token = Constants.prefs.getString("token");
    if (token == null) {
      _showErrorSnackBar("Authentication Error. Please log in again.");
      // Consider navigating to login: Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    OptionType type;
    String endpoint = '';
    bool alreadyLoaded = false;

    switch (index) {
      case 0:
        type = OptionType.topping;
        endpoint = '${Constants.baseUrl}/cake/toppings';
        if (!forceRefresh && _toppings.isNotEmpty) alreadyLoaded = true;
        if (forceRefresh || _toppings.isEmpty)
          setStateIfMounted(() => _isLoadingToppings = true);
        break;
      case 1:
        type = OptionType.sponge;
        endpoint = '${Constants.baseUrl}/cake/sponges';
        if (!forceRefresh && _sponges.isNotEmpty) alreadyLoaded = true;
        if (forceRefresh || _sponges.isEmpty)
          setStateIfMounted(() => _isLoadingSponges = true);
        break;
      case 2:
        type = OptionType.extra;
        endpoint = '${Constants.baseUrl}/cake/extras';
        if (!forceRefresh && _extras.isNotEmpty) alreadyLoaded = true;
        if (forceRefresh || _extras.isEmpty)
          setStateIfMounted(() => _isLoadingExtras = true);
        break;
      default:
        return;
    }

    if (alreadyLoaded) {
      // Ensure loading indicator is off if skipped
      setStateIfMounted(() {
        switch (type) {
          case OptionType.topping:
            _isLoadingToppings = false;
            break;
          case OptionType.sponge:
            _isLoadingSponges = false;
            break;
          case OptionType.extra:
            _isLoadingExtras = false;
            break;
        }
      });
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              "Authorization": "Token $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        if (decodedBody is Map &&
            decodedBody.containsKey('data') &&
            decodedBody['data'] is List) {
          final data = List<Map<String, dynamic>>.from(decodedBody['data']);
          setStateIfMounted(() {
            switch (type) {
              case OptionType.topping:
                _toppings = data;
                break;
              case OptionType.sponge:
                _sponges = data;
                break;
              case OptionType.extra:
                _extras = data;
                break;
            }
          });
        } else {
          throw Exception("Invalid data format received from server.");
        }
      } else {
        String errorMessage = 'Failed to load data';
        try {
          final responseData = json.decode(response.body);
          errorMessage =
              responseData['message'] ??
              'Failed to load data (Status code: ${response.statusCode})';
        } catch (_) {
          errorMessage =
              'Failed to load data (Status code: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Failed to fetch ${type.name}s: ${e.toString()}");
    } finally {
      setStateIfMounted(() {
        switch (type) {
          case OptionType.topping:
            _isLoadingToppings = false;
            break;
          case OptionType.sponge:
            _isLoadingSponges = false;
            break;
          case OptionType.extra:
            _isLoadingExtras = false;
            break;
        }
      });
    }
  }

  // --- Add/Edit Operation ---
  Future<void> _saveOption({
    required OptionType type,
    required Map<String, String> data,
    String? slug, // If slug is provided, it's an edit operation
  }) async {
    // No need to check mounted here as it's called from dialog which checks

    final String? token = Constants.prefs.getString("token");
    if (token == null) {
      _showErrorSnackBar("Authentication Error. Please log in again.");
      return; // Let the dialog handle resetting its loading state
    }

    // Loading state is handled inside the dialog's StatefulBuilder

    String endpoint = '';
    String operation = slug == null ? 'add' : 'edit';

    // Determine API endpoint (assuming API uses the same endpoint for add/edit)
    switch (type) {
      case OptionType.topping:
        endpoint = '${Constants.baseUrl}/cake/topping/add/';
        break;
      case OptionType.sponge:
        endpoint = '${Constants.baseUrl}/cake/sponge/add/';
        break;
      case OptionType.extra:
        endpoint = '${Constants.baseUrl}/cake/extra/add/';
        break;
    }

    Map<String, String> payload = {...data}; // Copy data
    if (slug != null) {
      payload['slug'] = slug; // Add slug if editing
    }

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              "Authorization": "Token $token",
              "Content-Type": "application/json",
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 20));

      // Check mounted *after* the await call, before updating UI/state
      if (!mounted) return;

      dynamic responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        throw Exception("Invalid server response.");
      }

      if ((response.statusCode == 200) || responseData['success'] == true) {
        // Success - dialog will be popped, show snackbar, refresh list
        Navigator.pop(context); // Close the dialog
        _showSuccessSnackBar(
          "${type.name.capitalize()} ${operation == 'add' ? 'added' : 'updated'} successfully!",
        );
        _fetchDataForTab(
          _tabController.index,
          forceRefresh: true,
        ); // Refresh the current list
      } else {
        // Failure - throw exception to be caught below
        throw Exception(
          responseData['message'] ?? 'Failed to ${operation} ${type.name}',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      // Let the caller (dialog) handle the error UI if needed
      // but show a general snackbar error as well
      _showErrorSnackBar("Error ${operation}ing ${type.name}: ${e.toString()}");
      // Rethrow to allow dialog to handle its loading state reset in catchError
      rethrow;
    }
    // 'finally' block is not needed here as loading state reset is handled
    // in the dialog's .then() and .catchError() clauses
  }

  // --- UI: Show Add/Edit Dialog ---
  void _showSaveDialog({Map<String, dynamic>? itemToEdit}) {
    final currentTabIndex = _tabController.index;
    final bool isEditing = itemToEdit != null;
    OptionType currentType;
    String title;

    // Determine type based on tab index
    switch (currentTabIndex) {
      case 0:
        currentType = OptionType.topping;
        break;
      case 1:
        currentType = OptionType.sponge;
        break;
      case 2:
        currentType = OptionType.extra;
        break;
      default:
        return;
    }
    title =
        "${isEditing ? 'Edit' : 'Add New'} ${currentType.name.capitalize()}";

    // --- Dialog-specific state ---
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    // Category state is managed inside StatefulBuilder

    // Pre-fill basic controllers if editing
    if (isEditing) {
      // Use 'sponge' key for sponge name, 'name' for others
      nameController.text =
          (currentType == OptionType.sponge)
              ? itemToEdit!['sponge'] ?? ''
              : itemToEdit!['name'] ?? '';
      priceController.text = itemToEdit['price']?.toString() ?? '';
    }
    // --- End Dialog-specific state ---

    showDialog(
      context: context,
      barrierDismissible:
          false, // Initially prevent dismissal while loading potentially
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage dialog's local state (isLoading, selectedCategory)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // --- StatefulBuilder local state ---
            bool isLoading =
                false; // Tracks submission state *within* the dialog
            String?
            selectedCategoryValue; // Holds the selected category *value*

            // Pre-fill category if editing Extras and category is valid
            if (isEditing && currentType == OptionType.extra) {
              final existingCategory = itemToEdit!['category'] as String?;
              if (existingCategory != null &&
                  extraCategoryChoices.containsKey(existingCategory)) {
                selectedCategoryValue = existingCategory;
              } else if (existingCategory != null) {
                print(
                  "Warning: Existing category '$existingCategory' from API is not in the valid choices.",
                );
              }
            }
            // --- End StatefulBuilder local state ---

            // Build form fields dynamically
            List<Widget> formFields;
            if (currentType == OptionType.extra) {
              formFields = [
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategoryValue,
                  items:
                      extraCategoryChoices.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key, // The backend value
                          child: Text(entry.value), // The display name
                        );
                      }).toList(),
                  onChanged:
                      isLoading
                          ? null
                          : (String? newValue) {
                            setDialogState(() {
                              selectedCategoryValue = newValue;
                            });
                          },
                  decoration: _buildInputDecoration(
                    theme: Theme.of(context),
                    label: "Category",
                  ),
                  validator:
                      (value) =>
                          value == null ? 'Please select a category' : null,
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  nameController,
                  "Extra Name",
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  priceController,
                  "Price",
                  isNumeric: true,
                  isLoading: isLoading,
                ),
              ];
            } else {
              // Topping or Sponge
              String nameLabel =
                  (currentType == OptionType.sponge)
                      ? "Sponge Name"
                      : "Topping Name";
              formFields = [
                _buildDialogTextField(
                  nameController,
                  nameLabel,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  priceController,
                  "Price",
                  isNumeric: true,
                  isLoading: isLoading,
                ),
              ];
            }

            return WillPopScope(
              // Control back button behavior during loading
              onWillPop: () async => !isLoading, // Prevent closing if loading
              child: AlertDialog(
                title: Text(title),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: formFields,
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              if (formKey.currentState!.validate()) {
                                Map<String, String> data = {
                                  'name':
                                      nameController.text
                                          .trim(), // API expects 'name'
                                  'price': priceController.text.trim(),
                                };
                                if (currentType == OptionType.extra) {
                                  if (selectedCategoryValue == null) {
                                    return;
                                  } // Should be caught by validator
                                  data['category'] = selectedCategoryValue!;
                                }

                                // Update dialog state to show loading
                                setDialogState(() => isLoading = true);

                                // Call the save function
                                _saveOption(
                                      type: currentType,
                                      data: data,
                                      slug:
                                          isEditing
                                              ? itemToEdit!['slug'] as String?
                                              : null,
                                    )
                                    .then((_) {
                                      // If saveOption succeeded, it pops the dialog.
                                      // If it failed, we need to reset loading state here.
                                      // However, the pop happens *before* this .then() sometimes.
                                      // Best practice: Let saveOption handle the pop on success.
                                      // Reset loading state regardless in case of failure.
                                      // Check if dialog is still active before setting state.
                                      if (mounted &&
                                          Navigator.of(context).canPop()) {
                                        setDialogState(() => isLoading = false);
                                      }
                                    })
                                    .catchError((_) {
                                      // Error occurred during saveOption
                                      if (mounted &&
                                          Navigator.of(context).canPop()) {
                                        setDialogState(() => isLoading = false);
                                      }
                                    });
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(isEditing ? "Save Changes" : "Add"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UI: Helper for Dialog TextFields ---
  Widget _buildDialogTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    bool isLoading = false, // Added to disable field during load
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      enabled: !isLoading, // Disable field if dialog is loading
      decoration: _buildInputDecoration(
        theme: theme,
        label: label,
      ), // Use common decoration
      keyboardType:
          isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      inputFormatters:
          isNumeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
              : [],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label cannot be empty';
        }
        if (isNumeric && double.tryParse(value.trim()) == null) {
          return 'Please enter a valid number';
        }
        return null; // Valid
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // --- UI: Common InputDecoration Builder ---
  InputDecoration _buildInputDecoration({
    required ThemeData theme,
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
      ),
      disabledBorder: OutlineInputBorder(
        // Style when disabled
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      filled: true, // Add a subtle background fill
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // --- UI: Build List View for a Tab ---
  Widget _buildListView(
    OptionType type,
    List<Map<String, dynamic>> items,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.grey[400],
              ), // More relevant icon
              const SizedBox(height: 12),
              Text(
                "No ${type.name}s Found", // Title case
                style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the '+' button below to add your first ${type.name}.",
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String categoryDisplayName = '';
        if (type == OptionType.extra) {
          categoryDisplayName =
              extraCategoryChoices[item['category']] ??
              item['category'] ??
              'Uncategorized';
        }
        return _buildListItemCard(
          item,
          type,
          theme,
          textTheme,
          categoryDisplayName: categoryDisplayName,
        );
      },
    );
  }

  // --- UI: Helper Widget for List Item Card ---
  Widget _buildListItemCard(
    Map<String, dynamic> item,
    OptionType type,
    ThemeData theme,
    TextTheme textTheme, {
    String categoryDisplayName = '',
  }) {
    // Use 'sponge' key for sponge title, 'name' for others
    String titleText =
        (type == OptionType.sponge)
            ? item['sponge'] ?? 'Unnamed Sponge'
            : item['name'] ?? 'Unnamed Item';

    String subtitleText;
    if (type == OptionType.extra) {
      subtitleText =
          'Category: $categoryDisplayName | Price: ₹${item['price'] ?? 'N/A'}';
    } else {
      subtitleText = 'Price: ₹${item['price'] ?? 'N/A'}';
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        title: Text(
          titleText,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitleText,
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.secondary),
          tooltip: 'Edit ${type.name.capitalize()}',
          onPressed: () {
            if (item['slug'] != null) {
              _showSaveDialog(itemToEdit: item);
            } else {
              _showErrorSnackBar(
                "Cannot edit item: Missing identifier (slug).",
              );
              print("Error: Edit action failed for item without slug: $item");
            }
          },
        ),
      ),
    );
  }

  // --- UI: Snackbars ---
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 10), // Adjust margin
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 10), // Adjust margin
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Helper to safely call setState only if the widget is still mounted
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text("Manage Cake Options"),
        elevation: 3.0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: "Toppings", icon: Icon(Icons.icecream_outlined)),
            Tab(text: "Sponges", icon: Icon(Icons.cake_outlined)),
            Tab(text: "Extras", icon: Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListView(OptionType.topping, _toppings, _isLoadingToppings),
            _buildListView(OptionType.sponge, _sponges, _isLoadingSponges),
            _buildListView(OptionType.extra, _extras, _isLoadingExtras),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSaveDialog(), // Call dialog for adding
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        icon: const Icon(Icons.add),
        label: const Text("Add New"),
        tooltip: 'Add New Option',
      ),
    );
  }
}
