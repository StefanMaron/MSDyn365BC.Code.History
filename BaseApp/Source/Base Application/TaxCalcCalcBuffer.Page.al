page 17324 "Tax Calc. Calc. Buffer"
{
    Caption = 'Tax Calc. Calc. Buffer';
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
                    ToolTip = 'Specifies the amount type associated with the tax calculation term line.';
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

    var
        Text1000: Label 'Filtering by Global Dimensions only.';

    [Scope('OnPrem')]
    procedure BuildTmpCalcBuffer(TaxCalcAccumulation: Record "Tax Calc. Accumulation")
    var
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumulation2: Record "Tax Calc. Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TaxCalcRecordRef: RecordRef;
        AccumulateRecordRef: RecordRef;
        TaxCalcFieldRef: FieldRef;
    begin
        with TaxCalcAccumulation do
            if TaxCalcLine.Get("Section Code", "Register No.", "Template Line No.") then begin
                TaxCalcRecordRef.GetTable(TaxCalcLine);
                TaxCalcFieldRef := TaxCalcRecordRef.Field(TaxCalcLine.FieldNo("Date Filter"));
                TaxCalcFieldRef.SetRange("Starting Date", "Ending Date");
                TaxCalcAccumulation2 := TaxCalcAccumulation;
                TaxCalcAccumulation2.SetCurrentKey("Section Code", "Register No.");
                TaxCalcAccumulation2.SetRange("Ending Date", "Ending Date");
                TaxCalcAccumulation2.SetRange("Section Code", "Section Code");
                AccumulateRecordRef.GetTable(TaxCalcAccumulation2);
                AccumulateRecordRef.SetView(TaxCalcAccumulation2.GetView(false));
                TaxRegTermMgt.ShowExpressionValue(TaxCalcRecordRef, Rec, AccumulateRecordRef);
            end;
    end;

    [Scope('OnPrem')]
    procedure DimensionsFilters()
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        CalcFields("Dimensions Filters");
        if "Dimensions Filters" then begin
            TaxCalcDimFilter.FilterGroup(2);
            TaxCalcDimFilter.SetRange("Section Code", "Section Code");
            TaxCalcDimFilter.SetRange("Register No.", "Tax Register No.");
            TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::Template);
            TaxCalcDimFilter.FilterGroup(0);
            TaxCalcDimFilter.SetRange("Line No.", "Template Line No.");
            if ACTION::None = PAGE.RunModal(0, TaxCalcDimFilter) then;
        end;
    end;

    local procedure DrillDownAmount()
    var
        TaxRegTermName: Record "Tax Calc. Term";
        TaxRegTermLine: Record "Tax Calc. Term Formula";
        GLEntry: Record "G/L Entry";
        GLCorrespondEntry: Record "G/L Correspondence Entry";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TempDimBuf0: Record "Dimension Buffer" temporary;
        TempGLEntryGlobalDimFilter: Record "G/L Entry" temporary;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        NoGlobalDimFilterNeed: Boolean;
    begin
        if "Expression Type" = "Expression Type"::Term then
            if TaxRegTermName.Get("Section Code", Expression) then
                if (TaxRegTermName."Expression Type" <> TaxRegTermName."Expression Type"::Compare) and
                   ("Term Type" < "Term Type"::Compare)
                then
                    if TaxRegTermLine.Get("Section Code", Expression, "Term Line No.") then begin
                        TaxRegTermMgt.CopyTemplateDimFilters(TempDimBuf0, "Section Code", "Tax Register No.", "Template Line No.");
                        NoGlobalDimFilterNeed := TaxRegTermMgt.SetDimFilters2GLEntry(TempGLEntryGlobalDimFilter, TempDimBuf0);
                        if NoGlobalDimFilterNeed then
                            Message(Text1000);
                        case TaxRegTermLine."Account Type" of
                            TaxRegTermLine."Account Type"::"GL Acc":
                                begin
                                    GLEntry.Reset;
                                    if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                                        GLEntry.SetFilter("G/L Account No.", TaxRegTermLine."Account No.");
                                        GLEntry.SetFilter("Posting Date", "Date Filter");
                                    end else begin
                                        GLEntry.SetCurrentKey(
                                          "G/L Account No.", "Business Unit Code",
                                          "Global Dimension 1 Code", "Global Dimension 2 Code");
                                        GLEntry.SetFilter("G/L Account No.", TaxRegTermLine."Account No.");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 1 Code", GLEntry."Global Dimension 1 Code");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 2 Code", GLEntry."Global Dimension 2 Code");
                                    end;
                                    GLEntry.SetFilter("Posting Date", "Date Filter");
                                    if TaxRegTermLine."Amount Type" = TaxRegTermLine."Amount Type"::Debit then
                                        GLEntry.SetFilter("Debit Amount", '<>%1', 0);
                                    if TaxRegTermLine."Amount Type" = TaxRegTermLine."Amount Type"::Credit then
                                        GLEntry.SetFilter("Credit Amount", '<>%1', 0);
                                    PAGE.RunModal(0, GLEntry);
                                end;
                            TaxRegTermLine."Account Type"::"Net Change":
                                begin
                                    GLCorrespondEntry.Reset;
                                    if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                        GLCorrespondEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
                                        GLCorrespondEntry.SetFilter("Debit Account No.", TaxRegTermLine."Account No.");
                                        GLCorrespondEntry.SetFilter("Credit Account No.", TaxRegTermLine."Bal. Account No.");
                                    end else begin
                                        GLCorrespondEntry.SetCurrentKey(
                                          "Debit Account No.", "Credit Account No.",
                                          "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code",
                                          "Business Unit Code", "Posting Date");
                                        GLCorrespondEntry.SetFilter("Debit Account No.", TaxRegTermLine."Account No.");
                                        GLCorrespondEntry.SetFilter("Credit Account No.", TaxRegTermLine."Bal. Account No.");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 1 Code", GLCorrespondEntry."Debit Global Dimension 1 Code");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 2 Code", GLCorrespondEntry."Debit Global Dimension 2 Code");
                                    end;
                                    GLCorrespondEntry.SetFilter("Posting Date", "Date Filter");
                                    PAGE.RunModal(0, GLCorrespondEntry);
                                end;
                        end;
                    end;
        if "Expression Type" = "Expression Type"::Total then begin
            if StrPos("Date Filter", '..') > 0 then begin
                if not Evaluate(TaxCalcAccumulation."Starting Date", CopyStr("Date Filter", 1, StrPos("Date Filter", '..') - 1)) then
                    exit;
                if not Evaluate(TaxCalcAccumulation."Ending Date", CopyStr("Date Filter", StrPos("Date Filter", '..') + 2)) then
                    exit;
            end else begin
                if not Evaluate(TaxCalcAccumulation."Ending Date", "Date Filter") then
                    exit;
                TaxCalcAccumulation."Starting Date" := 0D;
            end;
            TaxCalcAccumulation."Template Line No." := "Template Line No.";
            TaxCalcAccumulation."Register No." := "Tax Register No.";
            TaxCalcAccumulation."Section Code" := "Section Code";
            TaxCalcAccumulation.SetRange("Date Filter", TaxCalcAccumulation."Starting Date", TaxCalcAccumulation."Ending Date");
            TaxCalcAccumulation.DrillDownAmount;
        end;
    end;
}

