page 17216 "Tax Register Calc. Buffer"
{
    Caption = 'Tax Register Calc. Buffer';
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
                    Visible = false;
                }
                field(Operation; Operation)
                {
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ToolTip = 'Specifies the purpose of the account.';
                    Visible = false;
                }
                field("Amount Type"; "Amount Type")
                {
                    ToolTip = 'Specifies the amount type associated with the tax register line setup information.';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ToolTip = 'Specifies the G/L account number.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Process Sign"; "Process Sign")
                {
                    ToolTip = 'Specifies the process sign. Norm jurisdictions are based on Russian tax laws that define a variety of tax rates. They are used to calculate taxable profits and losses in tax accounting. Process signs include Skip Negative, Skip Positive, Always Positive, Always Negative.';
                    Visible = false;
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
    procedure BuildTaxRegCalcBuffer(TaxRegAccumulation: Record "Tax Register Accumulation")
    var
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TemplateRecordRef: RecordRef;
        AccumulateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
    begin
        with TaxRegAccumulation do
            if TaxRegTemplate.Get("Section Code", "Tax Register No.", "Template Line No.") then begin
                TemplateRecordRef.GetTable(TaxRegTemplate);
                TemplateFieldRef := TemplateRecordRef.Field(TaxRegTemplate.FieldNo("Date Filter"));
                TemplateFieldRef.SetRange("Starting Date", "Ending Date");
                TaxRegAccumulation2 := TaxRegAccumulation;
                TaxRegAccumulation2.SetCurrentKey("Section Code", "Tax Register No.");
                TaxRegAccumulation2.SetRange("Ending Date", TaxRegAccumulation2."Ending Date");
                TaxRegAccumulation2.SetRange("Section Code", TaxRegAccumulation2."Section Code");
                AccumulateRecordRef.GetTable(TaxRegAccumulation2);
                AccumulateRecordRef.SetView(TaxRegAccumulation2.GetView(false));
                TaxRegTermMgt.ShowExpressionValue(TemplateRecordRef, Rec, AccumulateRecordRef);
            end;
    end;

    [Scope('OnPrem')]
    procedure DimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        CalcFields("Dimensions Filters");
        if "Dimensions Filters" then begin
            TaxRegDimFilter.FilterGroup(2);
            TaxRegDimFilter.SetRange("Section Code", "Section Code");
            TaxRegDimFilter.SetRange("Tax Register No.", "Tax Register No.");
            TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
            TaxRegDimFilter.FilterGroup(0);
            TaxRegDimFilter.SetRange("Line No.", "Template Line No.");
            if ACTION::None = PAGE.RunModal(0, TaxRegDimFilter) then;
        end;
    end;
}

