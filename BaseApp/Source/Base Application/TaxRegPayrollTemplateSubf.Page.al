page 17238 "Tax Reg. Payroll Template Subf"
{
    AutoSplitKey = true;
    Caption = 'Template Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Report Line Code"; "Report Line Code")
                {
                    ToolTip = 'Specifies the report line code associated with the tax register template.';
                    Visible = false;
                }
                field("Link Tax Register No."; "Link Tax Register No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the link tax register number associated with the tax register template.';
                    Visible = false;
                }
                field("Sum Field No."; "Sum Field No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the sum field number associated with the tax register template.';
                    Visible = false;
                }
                field("Line Code"; "Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the tax register template.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Term Line Code"; "Term Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term line code associated with the tax register template.';
                }
                field("FA Type"; "FA Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset type associated with the tax register template.';
                }
                field("Belonging to Manufacturing"; "Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax register template belongs to Production or to Nonproduction.';
                }
                field("Depreciation Group"; "Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax register template.';
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the department code associated with the tax register template.';
                }
                field("Element Type Filter"; "Element Type Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type filter associated with the tax register template.';

                    trigger OnAssistEdit()
                    begin
                        AssistEditElementTypeTotaling;
                    end;

                    trigger OnDrillDown()
                    begin
                        DrillDownElementTypeTotaling;
                    end;
                }
                field("Payroll Source Filter"; "Payroll Source Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll source filter associated with the tax register template.';

                    trigger OnAssistEdit()
                    begin
                        AssistEditSourcePayTotaling;
                    end;

                    trigger OnDrillDown()
                    begin
                        DrillDownSourcePayTotaling;
                    end;
                }
                field("Element Type Totaling"; "Element Type Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type totaling associated with the tax register template.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupElementTypeTotaling(Text));
                    end;
                }
                field("Payroll Source Totaling"; "Payroll Source Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payroll source totaling associated with the tax register template.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupSourcePayTotaling(Text));
                    end;
                }
                field(Indentation; Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field(Bold; Bold)
                {
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                    Visible = false;
                }
                field(Period; Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the tax register template.';
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    DrillDown = false;
                    HideValue = DimFiltersHideValue;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        ShowDimensionsFilters;
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
        DimFiltersHideValue := false;
        DescriptionIndent := 0;
        CalcFields("Dimensions Filters");
        if "Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';
        DescriptionOnFormat;
        ElementTypeFilterOnFormat(Format("Element Type Filter"));
        PayrollSourceFilterOnFormat(Format("Payroll Source Filter"));
        DimFiltersOnFormat(Format(DimFilters));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Expression Type" := "Expression Type"::SumField;
        "Link Tax Register No." := Code;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Expression Type" := "Expression Type"::SumField;
        "Link Tax Register No." := Code;
        DimFilters := '';
    end;

    var
        Text1001: Label 'Present';
        DimFilters: Text[30];
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        DimFiltersHideValue: Boolean;

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegSection: Record "Tax Register Section";
        DimCodeFilter: Text[1024];
    begin
        CurrPage.SaveRecord;
        Commit;
        if ("Line No." <> 0) and ("Expression Type" = "Expression Type"::SumField) then begin
            TaxRegSection.Get("Section Code");
            if (TaxRegSection."Dimension 1 Code" <> '') or
               (TaxRegSection."Dimension 2 Code" <> '') or
               (TaxRegSection."Dimension 3 Code" <> '') or
               (TaxRegSection."Dimension 4 Code" <> '')
            then begin
                TaxRegDimFilter.FilterGroup(2);
                TaxRegDimFilter.SetRange("Section Code", "Section Code");
                TaxRegDimFilter.SetRange("Tax Register No.", Code);
                TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
                if TaxRegSection."Dimension 1 Code" <> '' then
                    DimCodeFilter := TaxRegSection."Dimension 1 Code";
                if TaxRegSection."Dimension 2 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 2 Code");
                if TaxRegSection."Dimension 3 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 3 Code");
                if TaxRegSection."Dimension 4 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 4 Code");
                DimCodeFilter := DelChr(DimCodeFilter, '<', '|');
                TaxRegDimFilter.SetFilter("Dimension Code", DimCodeFilter);
                TaxRegDimFilter.FilterGroup(0);
                TaxRegDimFilter.SetRange("Line No.", "Line No.");
                PAGE.RunModal(0, TaxRegDimFilter);
            end;
        end;
        CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Indentation;
        DescriptionEmphasize := Bold;
    end;

    local procedure ElementTypeFilterOnFormat(Text: Text[1024])
    begin
        Text := FormatElementTypeTotaling;
    end;

    local procedure PayrollSourceFilterOnFormat(Text: Text[1024])
    begin
        Text := FormatSourcePayTotaling;
    end;

    local procedure DimFiltersOnFormat(Text: Text[1024])
    begin
        if "Dimensions Filters" then
            Text := Text1001
        else
            DimFiltersHideValue := true;
    end;
}

