page 17286 "Tax Reg. Norm Calc. Buffer"
{
    Caption = 'Norm Calc. Buffer';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Register Calc. Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Code"; "Line Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Expression Type"; "Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 :;
                    ToolTip = 'Specifies the amount.';

                    trigger OnDrillDown()
                    begin
                        DrillDownAmount;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Dimensions Filters"; "Dimensions Filters")
                {
                    ToolTip = 'Specifies the dimension that the data is filtered by.';
                    Visible = false;
                }
                field("Term Type"; "Term Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Operation; Operation)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount type associated with the norm term line.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                }
                field("Process Sign"; "Process Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the process sign. Norm jurisdictions are based on Russian tax laws that define a variety of tax rates. They are used to calculate taxable profits and losses in tax accounting. Process signs include Skip Negative, Skip Positive, Always Positive, Always Negative.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
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
                        DimensionsFilters;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure BuildCalcBuffer(TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation")
    var
        TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
        TaxRegNormAccumulation2: Record "Tax Reg. Norm Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TemplateRecordRef: RecordRef;
        AccumulateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        with TaxRegNormAccumulation do
            if TaxRegNormTemplateLine.Get("Norm Jurisdiction Code", "Norm Group Code", "Template Line No.") then begin
                TemplateRecordRef.GetTable(TaxRegNormTemplateLine);
                TemplateFieldRef := TemplateRecordRef.Field(TaxRegNormTemplateLine.FieldNo("Date Filter"));
                TemplateFieldRef.SetRange("Starting Date", "Ending Date");
                TaxRegNormAccumulation2 := TaxRegNormAccumulation;
                TaxRegNormAccumulation2.SetCurrentKey("Norm Jurisdiction Code", "Norm Group Code");
                TaxRegNormAccumulation2.SetRange("Ending Date", TaxRegNormAccumulation2."Ending Date");
                TaxRegNormAccumulation2.SetRange("Norm Jurisdiction Code", TaxRegNormAccumulation2."Norm Jurisdiction Code");
                AccumulateRecordRef.GetTable(TaxRegNormAccumulation2);
                AccumulateRecordRef.SetView(TaxRegNormAccumulation2.GetView(false));
                TaxRegTermMgt.ShowExpressionValue(TemplateRecordRef, Rec, AccumulateRecordRef);
            end;
    end;

    [Scope('OnPrem')]
    procedure DimensionsFilters()
    var
        TaxRegNormDimFilter: Record "Tax Reg. Norm Dim. Filter";
    begin
        CalcFields("Dimensions Filters");
        if "Dimensions Filters" then begin
            TaxRegNormDimFilter.FilterGroup(2);
            TaxRegNormDimFilter.SetRange("Norm Jurisdiction Code", "Section Code");
            TaxRegNormDimFilter.SetRange("Norm Group Code", "Tax Register No.");
            TaxRegNormDimFilter.SetRange("Line No.", TaxRegNormDimFilter."Line No.");
            TaxRegNormDimFilter.FilterGroup(0);
            TaxRegNormDimFilter.SetRange("Line No.", "Template Line No.");
            if ACTION::None = PAGE.RunModal(0, TaxRegNormDimFilter) then;
        end;
    end;
}

