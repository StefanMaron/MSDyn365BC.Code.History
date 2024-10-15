enum 485 "Business Chart Type"
{
    Extensible = true;
    AssignmentCompatibility = true;
    ObsoleteReason = 'The enum will be moved to System Application.';
    ObsoleteState = Pending;
    ObsoleteTag = '19.5';

    value(0; "Point") { Caption = 'Point'; }
    value(2; "Bubble") { Caption = 'Bubble'; }
    value(3; "Line") { Caption = 'Line'; }
    value(5; "StepLine") { Caption = 'StepLine'; }
    value(10; "Column") { Caption = 'Column'; }
    value(11; "StackedColumn") { Caption = 'StackedColumn'; }
    value(12; "StackedColumn100") { Caption = 'StackedColumn100'; }
    value(13; "Area") { Caption = 'Area'; }
    value(15; "StackedArea") { Caption = 'StackedArea'; }
    value(16; "StackedArea100") { Caption = 'StackedArea100'; }
    value(17; "Pie") { Caption = 'Pie'; }
    value(18; "Doughnut") { Caption = 'Doughnut'; }
    value(21; "Range") { Caption = 'Range'; }
    value(25; "Radar") { Caption = 'Radar'; }
    value(33; "Funnel") { Caption = 'Funnel'; }
}