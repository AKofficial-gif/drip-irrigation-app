import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UnifiedIrrigationSuiteScreen(),
  ));
}

class UnifiedIrrigationSuiteScreen extends StatefulWidget {
  const UnifiedIrrigationSuiteScreen({super.key});

  @override
  State<UnifiedIrrigationSuiteScreen> createState() =>
      _UnifiedIrrigationSuiteScreenState();
}

class _UnifiedIrrigationSuiteScreenState
    extends State<UnifiedIrrigationSuiteScreen> {
  int _currentStep = 0;

  double plotAreaSqm = 10000.0;
  String cropType = 'Sugarcane';
  double plantSpacingM = 1.5;
  double rowSpacingM = 0.6;

  String soilType = 'Loam Soil';
  double peakEtcMmDay = 5.2;
  double soilAwhcMmM = 150.0;
  double rootDepthM = 0.6;

  double efficiencyPercent = 90.0;
  double grossWaterMmDay = 0.0;
  double totalDailyVolumeM3 = 0.0;

  double emitterFlowLph = 4.0;
  double emitterSpacingM = 0.5;
  int emittersPerPlant = 1;
  int totalEmitters = 0;
  double totalSystemFlowLpm = 0.0;

  double lateralDiameterMm = 16.0;
  double maxLateralLengthM = 80.0;
  double lateralHeadLossM = 1.8;

  double mainPipeDiameterMm = 63.0;
  double mainLengthM = 150.0;
  double mainHeadLossM = 3.2;

  String filterType = 'Disc Filter (120 Mesh)';
  double filterHeadLossM = 3.0;

  double staticSuctionHeadM = 5.0;
  double operatingPressureHeadM = 15.0;
  double totalDynamicHeadM = 0.0;
  double pumpHorsePowerHp = 0.0;

  double pipeCostPerMeter = 45.0;
  double emitterCostPerUnit = 3.5;
  double pumpCost = 32000.0;
  double accessoriesAndLaborCost = 25000.0;
  double totalBudget = 0.0;

  double applicationRateMmHr = 0.0;
  int dailyRuntimeMinutes = 0;

  @override
  void initState() {
    super.initState();
    _recalculateAllModules();
  }

  void _recalculateAllModules() {
    setState(() {
      grossWaterMmDay = peakEtcMmDay / (efficiencyPercent / 100.0);
      totalDailyVolumeM3 = (plotAreaSqm * grossWaterMmDay) / 1000.0;

      double emitterAreaCoverage = plantSpacingM * rowSpacingM;
      totalEmitters = (plotAreaSqm / emitterAreaCoverage).round();
      double systemFlowLph = totalEmitters * emitterFlowLph;
      totalSystemFlowLpm = systemFlowLph / 60.0;

      lateralHeadLossM = 1.2 * (maxLateralLengthM / 50.0);
      mainHeadLossM = 2.5 * (mainLengthM / 100.0);

      totalDynamicHeadM = staticSuctionHeadM +
          operatingPressureHeadM +
          lateralHeadLossM +
          mainHeadLossM +
          filterHeadLossM;
      double flowLps = totalSystemFlowLpm / 60.0;
      pumpHorsePowerHp = (flowLps * totalDynamicHeadM) / (75.0 * 0.65);
      if (pumpHorsePowerHp < 1.0) pumpHorsePowerHp = 1.0;

      double totalLateralPipeM = (plotAreaSqm / rowSpacingM);
      double pipingTotalCost =
          (totalLateralPipeM * 12.0) + (mainLengthM * pipeCostPerMeter);
      double emitterTotalCost = totalEmitters * emitterCostPerUnit;
      totalBudget =
          pipingTotalCost + emitterTotalCost + pumpCost + accessoriesAndLaborCost;

      applicationRateMmHr = emitterFlowLph / (emitterSpacingM * rowSpacingM);
      if (applicationRateMmHr > 0) {
        double hoursPerDay = grossWaterMmDay / applicationRateMmHr;
        dailyRuntimeMinutes = (hoursPerDay * 60).round();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drip Suite: Master Module (1-10)'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 9) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (_currentStep < 9)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[800],
                        foregroundColor: Colors.white),
                    child: const Text('Next Module'),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Previous'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          _buildStep(
            title: 'Module 1: Crop & Field Parameters',
            content: _buildModule1(),
            isActive: _currentStep == 0,
          ),
          _buildStep(
            title: 'Module 2: Soil & Climate Analysis',
            content: _buildModule2(),
            isActive: _currentStep == 1,
          ),
          _buildStep(
            title: 'Module 3: Daily Water Demand',
            content: _buildModule3(),
            isActive: _currentStep == 2,
          ),
          _buildStep(
            title: 'Module 4: Emitter & Flow Layout',
            content: _buildModule4(),
            isActive: _currentStep == 3,
          ),
          _buildStep(
            title: 'Module 5: Lateral Hydraulics',
            content: _buildModule5(),
            isActive: _currentStep == 4,
          ),
          _buildStep(
            title: 'Module 6: Mainline Hydraulics',
            content: _buildModule6(),
            isActive: _currentStep == 5,
          ),
          _buildStep(
            title: 'Module 7: Headwork & Filtration',
            content: _buildModule7(),
            isActive: _currentStep == 6,
          ),
          _buildStep(
            title: 'Module 8: Pump & Energy Rating',
            content: _buildModule8(),
            isActive: _currentStep == 7,
          ),
          _buildStep(
            title: 'Module 9: Bill of Materials (BOM)',
            content: _buildModule9(),
            isActive: _currentStep == 8,
          ),
          _buildStep(
            title: 'Module 10: Schedule & PDF Export',
            content: _buildModule10(),
            isActive: _currentStep == 9,
          ),
        ],
      ),
    );
  }

  Step _buildStep(
      {required String title,
      required Widget content,
      required bool isActive}) {
    return Step(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      content: content,
      isActive: isActive,
      state: isActive ? StepState.editing : StepState.indexed,
    );
  }

  Widget _buildModule1() {
    return Column(
      children: [
        TextFormField(
          initialValue: plotAreaSqm.toString(),
          decoration: const InputDecoration(
              labelText: 'Plot Area (m²)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            plotAreaSqm = double.tryParse(val) ?? plotAreaSqm;
            _recalculateAllModules();
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: plantSpacingM.toString(),
                decoration: const InputDecoration(
                    labelText: 'Plant Spacing (m)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  plantSpacingM = double.tryParse(val) ?? plantSpacingM;
                  _recalculateAllModules();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: rowSpacingM.toString(),
                decoration: const InputDecoration(
                    labelText: 'Row Spacing (m)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  rowSpacingM = double.tryParse(val) ?? rowSpacingM;
                  _recalculateAllModules();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModule2() {
    return Column(
      children: [
        TextFormField(
          initialValue: peakEtcMmDay.toString(),
          decoration: const InputDecoration(
              labelText: 'Peak Crop Evapotranspiration ETc (mm/day)',
              border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            peakEtcMmDay = double.tryParse(val) ?? peakEtcMmDay;
            _recalculateAllModules();
          },
        ),
        const SizedBox(height: 10),
        _buildInfoBox('Soil Type: $soilType | AWHC: ${soilAwhcMmM} mm/m'),
      ],
    );
  }

  Widget _buildModule3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
            'Gross Water Req: ${grossWaterMmDay.toStringAsFixed(2)} mm/day\nTotal Daily Volume: ${totalDailyVolumeM3.toStringAsFixed(1)} m³/day'),
      ],
    );
  }

  Widget _buildModule4() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: emitterFlowLph.toString(),
                decoration: const InputDecoration(
                    labelText: 'Emitter Discharge (LPH)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  emitterFlowLph = double.tryParse(val) ?? emitterFlowLph;
                  _recalculateAllModules();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: emitterSpacingM.toString(),
                decoration: const InputDecoration(
                    labelText: 'Emitter Spacing (m)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  emitterSpacingM = double.tryParse(val) ?? emitterSpacingM;
                  _recalculateAllModules();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildInfoBox(
            'Total Emitters: $totalEmitters units\nPeak System Flow Rate: ${totalSystemFlowLpm.toStringAsFixed(1)} LPM'),
      ],
    );
  }

  Widget _buildModule5() {
    return _buildInfoBox(
        'Lateral Diameter: ${lateralDiameterMm}mm LLDPE\nMax Length: ${maxLateralLengthM}m\nEstimated Friction Loss: ${lateralHeadLossM.toStringAsFixed(2)} m');
  }

  Widget _buildModule6() {
    return _buildInfoBox(
        'Mainline Pipe: ${mainPipeDiameterMm}mm PVC\nMain Length: ${mainLengthM}m\nMainline Friction Loss: ${mainHeadLossM.toStringAsFixed(2)} m');
  }

  Widget _buildModule7() {
    return _buildInfoBox(
        'Filter Station: $filterType\nRequired Capacity: > ${(totalSystemFlowLpm * 0.06).toStringAsFixed(1)} m³/hr\nHead Loss: ${filterHeadLossM} m');
  }

  Widget _buildModule8() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
            'Total Dynamic Head (TDH): ${totalDynamicHeadM.toStringAsFixed(2)} meters (${(totalDynamicHeadM / 10.2).toStringAsFixed(2)} bar)\nRecommended Pump Power: ${pumpHorsePowerHp.toStringAsFixed(1)} HP Submersible'),
      ],
    );
  }

  Widget _buildModule9() {
    return _buildInfoBox(
        'Estimated System Budget Breakdown:\n• Piping & Fittings: ₹${((plotAreaSqm / rowSpacingM) * 12 + mainLengthM * pipeCostPerMeter).toStringAsFixed(0)}\n• Emitters: ₹${(totalEmitters * emitterCostPerUnit).toStringAsFixed(0)}\n• Pump & Filters: ₹${(pumpCost + 15000).toStringAsFixed(0)}\n• Total Estimated Budget: ₹${totalBudget.toStringAsFixed(0)}');
  }

  Widget _buildModule10() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBox(
            'Daily Operating Schedule:\n• Drip Application Rate: ${applicationRateMmHr.toStringAsFixed(2)} mm/hr\n• Daily Runtime: ${(dailyRuntimeMinutes / 60).floor()} hours ${dailyRuntimeMinutes % 60} mins\n• Peak Flow Rate: ${totalSystemFlowLpm.toStringAsFixed(1)} LPM'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Colors.teal[800],
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export Consolidated System Report (PDF)'),
          onPressed: () => _exportConsolidatedPdf(),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.teal[900], fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Future<void> _exportConsolidatedPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.teal800,
                child: pw.Text(
                  'MASTER DRIP IRRIGATION SYSTEM DESIGN REPORT',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  _pdfRow('Module 1: Plot Area', '$plotAreaSqm m²'),
                  _pdfRow('Module 1: Crop Type', cropType),
                  _pdfRow('Module 2: Soil Type & ETc',
                      '$soilType ($peakEtcMmDay mm/day)'),
                  _pdfRow('Module 3: Daily Water Demand',
                      '${totalDailyVolumeM3.toStringAsFixed(1)} m³/day'),
                  _pdfRow('Module 4: System Flow Rate',
                      '${totalSystemFlowLpm.toStringAsFixed(1)} LPM ($totalEmitters emitters)'),
                  _pdfRow('Module 5 & 6: Main/Lateral Pipes',
                      '${mainPipeDiameterMm}mm Main / ${lateralDiameterMm}mm Lateral'),
                  _pdfRow('Module 7: Filter Station', filterType),
                  _pdfRow('Module 8: Required Pump Power',
                      '${pumpHorsePowerHp.toStringAsFixed(1)} HP (TDH: ${totalDynamicHeadM.toStringAsFixed(1)}m)'),
                  _pdfRow('Module 9: Total Investment Budget',
                      '₹${totalBudget.toStringAsFixed(0)}'),
                  _pdfRow('Module 10: Daily Operating Runtime',
                      '${(dailyRuntimeMinutes / 60).floor()}h ${dailyRuntimeMinutes % 60}m'),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Master_Drip_Irrigation_Report.pdf',
    );
  }

  pw.TableRow _pdfRow(String key, String val) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(key,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(val, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
