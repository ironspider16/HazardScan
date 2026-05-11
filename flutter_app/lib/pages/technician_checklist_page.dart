import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/design/style_constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/WAH_Permit.dart';
import '../../widgets/swp_checklist.dart';
import '../../widgets/Image_upload.dart';

class TechnicianChecklistPage extends StatefulWidget {
  final int templateId;
  const TechnicianChecklistPage({super.key, required this.templateId});

  @override
  State<TechnicianChecklistPage> createState() => _TechnicianChecklistPageState();
}

class _TechnicianChecklistPageState extends State<TechnicianChecklistPage> {
  final supabase = Supabase.instance.client;
  bool isSafetyCleared = false;
  bool isPtwCleared = false;
  String ptwNumber = '';
  String? categoryName;
  final List<File> _imageFiles = [];
  List<String> currentSWPItems = [];

  Future<void> fetchSWPItems(int templateId) async {
    final response = await supabase 
        .from('swp_items')
        .select('description, swp_templates(category)')
        .eq('template_id', templateId);

    setState(() {
      currentSWPItems = List<String>.from(response.map((x) => x['description']));
      if (response.isNotEmpty && response[0]['swp_templates'] != null) {
        categoryName = response[0]['swp_templates']['category'];
      }
      isSafetyCleared = false;
      isPtwCleared = categoryName!.contains("Work At Height") ? false : true; // If not WAH, PTW is not required
    });
  }

    @override
      void initState() {
      super.initState();
      fetchSWPItems(widget.templateId);
    }

  bool isSubmitting = false;

  void submitTask() {
    // TODO: implement task submission logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 420;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB((isMobile ? 10 : 30), 20, (isMobile ? 10 : 30), 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back),
                          ),
                        ],
                      ),
                      if (currentSWPItems.isNotEmpty)
                        Container(
                          padding: isMobile ? EdgeInsets.fromLTRB(5,16,5,16) : EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (categoryName?.toLowerCase() == "work at height")
                                WAHPermitWidget(
                                  isMobile: isMobile,
                                  onValidityChanged: (isAbove3m, ptwNum) 
                                  {
                                    setState((){
                                      this.ptwNumber = ptwNum;
                                      isPtwCleared = !isAbove3m || ptwNum.isNotEmpty;
                                    }
                                    
                                    );
                                  },
                                ),
                              
                          SWPChecklistWidget(
                            isMobile : isMobile,
                            items: currentSWPItems,
                            onAllChecked: (status) {
                              setState(() {
                                isSafetyCleared = status;
                              });
                            },
                          ),
                          const SizedBox(height:AppPadding.medium),
                          AppImageUpload(
                          label: "Capture Site Condition",
                          onImageSelected: (file) {
                            setState(() => _imageFiles.add(file));
                          },
                        ),

                        const SizedBox(height: AppPadding.medium),

                        if (_imageFiles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${_imageFiles.length} Compressed Photos Ready'),
                          ),
                        ]
                      ),
                    ),
                    SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (isSubmitting || !isSafetyCleared || !isPtwCleared) ? null : submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isSafetyCleared && isPtwCleared ? 'Submit Task' : 'Complete Checklist First'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
}
}