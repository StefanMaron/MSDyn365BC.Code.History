page 17312 "Tax Calc. Select Setup Subf"
{
    AutoSplitKey = true;
    Caption = 'Tax Calc. Select Setup';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Calc. Selection Setup";

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
                    ToolTip = 'Specifies the line code associated with the tax calculation selection setup information.';

                    trigger OnValidate()
                    begin
                        LineCodeOnAfterValidate;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with the tax calculation selection setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLAcc.Reset();
                        if "Account No." <> '' then begin
                            GLAcc.SetFilter("No.", "Account No.");
                            if GLAcc.FindFirst() then;
                            GLAcc.SetRange("No.");
                        end;
                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        AccountNoOnAfterValidate();
                    end;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLAcc.Reset();
                        if "Bal. Account No." <> '' then begin
                            GLAcc.SetFilter("No.", "Bal. Account No.");
                            if GLAcc.FindFirst() then;
                            GLAcc.SetRange("No.");
                        end;
                        if ACTION::LookupOK = PAGE.RunModal(0, GLAcc) then begin
                            Text := GLAcc."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        BalAccountNoOnAfterValidate();
                    end;
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        ShowDimensionsFilters;
                    end;
                }
                field(GLCorrDimFilters; GLCorrDimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Corr. Dimensions Filters';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the dimensions by which data is shown.';

                    trigger OnAssistEdit()
                    begin
                        ShowGLCorrDimensionsFilters;
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
        CalcFields("Dimensions Filters", "G/L Corr. Dimensions Filters");
        if "Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';

        if "G/L Corr. Dimensions Filters" then
            GLCorrDimFilters := Text1001
        else
            GLCorrDimFilters := '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupRegisterType;
    end;

    var
        GLAcc: Record "G/L Account";
        Text1001: Label 'Present';
        TaxCalcHeader: Record "Tax Calc. Header";
        DimFilters: Text[30];
        GLCorrDimFilters: Text[30];
        Text1002: Label '%1 should be used for this type of tax register.';

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TemplateDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        CurrPage.SaveRecord;
        Commit();
        TaxCalcHeader.Get("Section Code", "Register No.");
        if (TaxCalcHeader."Table ID" <> DATABASE::"Tax Calc. G/L Entry") and ("Line No." <> 0) then begin
            TemplateDimFilter.FilterGroup(2);
            TemplateDimFilter.SetRange("Section Code", "Section Code");
            TemplateDimFilter.SetRange("Register No.", "Register No.");
            TemplateDimFilter.SetRange(Define, TemplateDimFilter.Define::"Entry Setup");
            TemplateDimFilter.FilterGroup(0);
            TemplateDimFilter.SetRange("Line No.", "Line No.");
            PAGE.RunModal(0, TemplateDimFilter);
        end else
            Error(Text1002, FieldCaption("G/L Corr. Dimensions Filters"));
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure ShowGLCorrDimensionsFilters()
    var
        TaxDifGLCorrDimFilter: Record "Tax Diff. Corr. Dim. Filter";
    begin
        CurrPage.SaveRecord;
        Commit();
        TaxCalcHeader.Get("Section Code", "Register No.");
        if (TaxCalcHeader."Table ID" = DATABASE::"Tax Calc. G/L Entry") and ("Line No." <> 0) then begin
            TaxDifGLCorrDimFilter.FilterGroup(2);
            TaxDifGLCorrDimFilter.SetRange("Section Code", "Section Code");
            TaxDifGLCorrDimFilter.SetRange("Tax Calc. No.", "Register No.");
            TaxDifGLCorrDimFilter.SetRange(Define, TaxDifGLCorrDimFilter.Define::"Entry Setup");
            TaxDifGLCorrDimFilter.SetRange("Line No.", "Line No.");
            TaxDifGLCorrDimFilter.FilterGroup(0);
            PAGE.RunModal(0, TaxDifGLCorrDimFilter);
        end else
            Error(Text1002, FieldCaption("Dimensions Filters"));
        CurrPage.Update(false);
    end;

    local procedure LineCodeOnAfterValidate()
    begin
        if "Line Code" <> '' then
            CurrPage.SaveRecord;
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        if "Account No." <> '' then
            CurrPage.SaveRecord;
    end;

    local procedure BalAccountNoOnAfterValidate()
    begin
        if "Bal. Account No." <> '' then
            CurrPage.SaveRecord;
    end;
}

