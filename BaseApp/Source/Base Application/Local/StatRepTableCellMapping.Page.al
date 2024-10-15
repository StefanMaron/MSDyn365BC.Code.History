page 26594 "Stat. Rep. Table Cell Mapping"
{
    Caption = 'Stat. Rep. Table Cell Mapping';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Stat. Report Table Mapping";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Report Code"; Rec."Report Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the report code for statutory reports.';
                }
                field("Table Code"; Rec."Table Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table code associated with the statutory report.';
                }
                field("Table Row Description"; Rec."Table Row Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table row description associated with the statutory report.';
                }
                field("Table Column Header"; Rec."Table Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table column header associated with the statutory report.';
                }
                field("Int. Source Type"; Rec."Int. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source type for the statutory report.';

                    trigger OnValidate()
                    begin
                        IntSourceTypeOnAfterValidate();
                    end;
                }
                field("Int. Source Section Code"; Rec."Int. Source Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Int. Source Section CodeEnable";
                    ToolTip = 'Specifies the internal source section code associated with the statutory report.';
                }
                field("Int. Source No."; Rec."Int. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source number for statutory reports.';
                }
                field("Int. Source Row Description"; Rec."Int. Source Row Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the internal source row description associated with the statutory report.';

                    trigger OnDrillDown()
                    begin
                        case "Int. Source Type" of
                            "Int. Source Type"::"Acc. Schedule":
                                begin
                                    AccScheduleLine.FilterGroup(2);
                                    AccScheduleLine.SetRange("Schedule Name", "Int. Source No.");
                                    AccScheduleLine.FilterGroup(0);
                                    Clear(AccScheduleLines);
                                    AccScheduleLines.SetTableView(AccScheduleLine);
                                    if "Internal Source Row No." <> 0 then
                                        if AccScheduleLine.Get("Int. Source No.", "Internal Source Row No.") then
                                            AccScheduleLines.SetRecord(AccScheduleLine);
                                    AccScheduleLines.LookupMode := true;
                                    if AccScheduleLines.RunModal() = ACTION::LookupOK then begin
                                        AccScheduleLines.GetRecord(AccScheduleLine);
                                        "Internal Source Row No." := AccScheduleLine."Line No.";
                                        "Int. Source Row Description" := AccScheduleLine.Description;
                                    end;
                                end;
                            "Int. Source Type"::"Tax Register":
                                begin
                                    TaxRegisterTemplate.FilterGroup(2);
                                    TaxRegisterTemplate.SetRange("Section Code", "Int. Source Section Code");
                                    TaxRegisterTemplate.SetRange(Code, "Int. Source No.");
                                    TaxRegisterTemplate.FilterGroup(0);
                                    Clear(TaxRegisterTemplateLines);
                                    TaxRegisterTemplateLines.SetTableView(TaxRegisterTemplate);
                                    if "Internal Source Row No." <> 0 then
                                        if TaxRegisterTemplate.Get(
                                             "Int. Source Section Code",
                                             "Int. Source No.",
                                             "Internal Source Row No.")
                                        then
                                            TaxRegisterTemplateLines.SetRecord(TaxRegisterTemplate);
                                    TaxRegisterTemplateLines.LookupMode := true;
                                    if TaxRegisterTemplateLines.RunModal() = ACTION::LookupOK then begin
                                        TaxRegisterTemplateLines.GetRecord(TaxRegisterTemplate);
                                        "Internal Source Row No." := TaxRegisterTemplate."Line No.";
                                        "Int. Source Row Description" := TaxRegisterTemplate.Description;
                                    end;
                                end;
                            "Int. Source Type"::"Tax Difference":
                                begin
                                    TaxCalcLine.FilterGroup(2);
                                    TaxCalcLine.SetRange("Section Code", "Int. Source Section Code");
                                    TaxCalcLine.SetRange(Code, "Int. Source No.");
                                    TaxCalcLine.FilterGroup(0);
                                    Clear(TaxCalcLines);
                                    TaxCalcLines.SetTableView(TaxCalcLine);
                                    if "Internal Source Row No." <> 0 then
                                        if TaxCalcLine.Get(
                                             "Int. Source Section Code",
                                             "Int. Source No.",
                                             "Internal Source Row No.")
                                        then
                                            TaxCalcLines.SetRecord(TaxCalcLine);
                                    TaxCalcLines.LookupMode := true;
                                    if TaxCalcLines.RunModal() = ACTION::LookupOK then begin
                                        TaxCalcLines.GetRecord(TaxCalcLine);
                                        "Internal Source Row No." := TaxCalcLine."Line No.";
                                        "Int. Source Row Description" := TaxCalcLine.Description;
                                    end;
                                end;
                        end;
                    end;
                }
                field("Int. Source Column Header"; Rec."Int. Source Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = IntSourceColumnHeaderEnable;
                    ToolTip = 'Specifies the internal source column header associated with the statutory report.';

                    trigger OnDrillDown()
                    begin
                        case "Int. Source Type" of
                            "Int. Source Type"::"Acc. Schedule":
                                begin
                                    AccScheduleName.Get("Int. Source No.");
                                    AccScheduleName.TestField("Default Column Layout");
                                    ColumnLayout.FilterGroup(2);
                                    ColumnLayout.SetRange("Column Layout Name", AccScheduleName."Default Column Layout");
                                    ColumnLayout.FilterGroup(0);
                                    Clear(ColumnLayouts);
                                    ColumnLayouts.SetTableView(ColumnLayout);
                                    if "Internal Source Column No." <> 0 then
                                        if ColumnLayout.Get(AccScheduleName."Default Column Layout", "Internal Source Column No.") then
                                            ColumnLayouts.SetRecord(ColumnLayout);
                                    ColumnLayouts.LookupMode := true;
                                    if ColumnLayouts.RunModal() = ACTION::LookupOK then begin
                                        ColumnLayouts.GetRecord(ColumnLayout);
                                        "Internal Source Column No." := ColumnLayout."Line No.";
                                        "Int. Source Column Header" := ColumnLayout."Column Header";
                                    end;
                                end;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnInit()
    begin
        "Int. Source Section CodeEnable" := true;
        IntSourceColumnHeaderEnable := true;
    end;

    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TaxRegisterTemplate: Record "Tax Register Template";
        TaxCalcLine: Record "Tax Calc. Line";
        AccScheduleLines: Page "Acc. Schedule Lines";
        ColumnLayouts: Page "Column Layouts";
        TaxRegisterTemplateLines: Page "Tax Register Templates";
        TaxCalcLines: Page "Tax Calc. Lines";
        [InDataSet]
        IntSourceColumnHeaderEnable: Boolean;
        [InDataSet]
        "Int. Source Section CodeEnable": Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    var
        TaxReg: Boolean;
    begin
        TaxReg := "Int. Source Type" in ["Int. Source Type"::"Tax Register", "Int. Source Type"::"Tax Difference"];
        "Int. Source Section CodeEnable" := TaxReg;
        IntSourceColumnHeaderEnable := not TaxReg;
    end;

    [Scope('OnPrem')]
    procedure SetData(StatReportTableMapping: Record "Stat. Report Table Mapping")
    begin
        Rec := StatReportTableMapping;
        Insert();
    end;

    local procedure IntSourceTypeOnAfterValidate()
    begin
        UpdateControls();
    end;
}

