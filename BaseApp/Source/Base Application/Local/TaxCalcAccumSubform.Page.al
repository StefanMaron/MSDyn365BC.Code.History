page 17322 "Tax Calc. Accum. Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "Register No.";
    Editable = false;
    PageType = ListPart;
    SourceTable = "Tax Calc. Accumulation";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Template Line Code"; Rec."Template Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template line code associated with the tax calculation accumulation. ';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation accumulation. ';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the tax calculation accumulation. ';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownAmount();
                    end;
                }
                field("Dimensions Filters"; Rec."Dimensions Filters")
                {
                    ToolTip = 'Specifies the dimension that the data is filtered by.';
                    Visible = false;
                }
                field("Tax Diff. Amount (Base)"; Rec."Tax Diff. Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference base amount associated with the tax calculation accumulation. ';
                }
                field("Tax Diff. Amount (Tax)"; Rec."Tax Diff. Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference tax amount associated with the tax calculation accumulation. ';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        DimensionsFilters();
                    end;
                }
            }
            group(Register)
            {
                Caption = 'Register';
                Image = Register;
                action(Entries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries';
                    Image = Entries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries for the tax register.';

                    trigger OnAction()
                    begin
                        FormTemplateRun();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    var
        TaxCalcHeader: Record "Tax Calc. Header";
        DateFilter: Text[250];
        DescriptionIndent: Integer;

    [Scope('OnPrem')]
    procedure Load(NewTaxCalcHeader: Record "Tax Calc. Header"; NewDateFilter: Text[250])
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Section Code", NewTaxCalcHeader."Section Code");
        Rec.SetRange("Register No.", NewTaxCalcHeader."No.");
        Rec.SetFilter("Date Filter", NewDateFilter);
        Rec.SetRange("Ending Date", Rec.GetRangeMax("Date Filter"));
        Rec.FilterGroup(0);
        DateFilter := NewDateFilter;
        TaxCalcHeader := NewTaxCalcHeader;
    end;

    [Scope('OnPrem')]
    procedure FormTemplateRun()
    var
        TaxCalcEntry: Record "Tax Calc. G/L Entry";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
    begin
        with TaxCalcHeader do begin
            if ("Page ID" = 0) or
               ("Table ID" = 0) or
               ("Storing Method" = "Storing Method"::Calculation)
            then
                exit;
        end;

        case TaxCalcHeader."Table ID" of
            DATABASE::"Tax Calc. G/L Entry":
                with TaxCalcEntry do begin
                    FilterGroup(2);
                    SetFilter("Section Code", Rec."Section Code");
                    SetFilter("Where Used Register IDs", '*~' + TaxCalcHeader."Register ID" + '~*');
                    FilterGroup(0);
                    SetFilter("Date Filter", DateFilter);
                    PAGE.RunModal(TaxCalcHeader."Page ID", TaxCalcEntry);
                end;
            DATABASE::"Tax Calc. Item Entry":
                with TaxCalcItemEntry do begin
                    FilterGroup(2);
                    SetFilter("Section Code", Rec."Section Code");
                    SetFilter("Where Used Register IDs", '*~' + TaxCalcHeader."Register ID" + '~*');
                    FilterGroup(0);
                    SetFilter("Date Filter", DateFilter);
                    PAGE.RunModal(TaxCalcHeader."Page ID", TaxCalcItemEntry);
                end;
            DATABASE::"Tax Calc. FA Entry":
                with TaxCalcFAEntry do begin
                    FilterGroup(2);
                    SetFilter("Section Code", Rec."Section Code");
                    SetFilter("Where Used Register IDs", '*~' + TaxCalcHeader."Register ID" + '~*');
                    FilterGroup(0);
                    SetFilter("Date Filter", DateFilter);
                    PAGE.RunModal(TaxCalcHeader."Page ID", TaxCalcFAEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DimensionsFilters()
    var
        TemplateDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        Rec.CalcFields("Dimensions Filters");
        if Rec."Dimensions Filters" then begin
            TemplateDimFilter.FilterGroup(2);
            TemplateDimFilter.SetRange("Section Code", Rec."Section Code");
            TemplateDimFilter.SetRange("Register No.", Rec."Register No.");
            TemplateDimFilter.SetRange(Define, TemplateDimFilter.Define::Template);
            TemplateDimFilter.FilterGroup(0);
            TemplateDimFilter.SetRange("Line No.", Rec."Template Line No.");
            if ACTION::None = PAGE.RunModal(0, TemplateDimFilter) then;
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
    end;
}

