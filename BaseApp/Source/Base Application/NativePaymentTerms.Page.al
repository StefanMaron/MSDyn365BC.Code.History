page 2861 "Native - Payment Terms"
{
    Caption = 'nativePaymentTerms', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
    SourceTable = "Payment Terms";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
                    begin
                        RegisterFieldSet(FieldNo(Code));

                        if Default then
                            O365SalesInitialSetup.UpdateDefaultPaymentTerms(Code);
                    end;
                }
                field(displayName; DescriptionInCurrentLanguage)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                    ToolTip = 'Specifies the displayName.';

                    trigger OnValidate()
                    begin
                        if DescriptionInCurrentLanguage <> GetDescriptionInCurrentLanguage then begin
                            if StrLen(DescriptionInCurrentLanguage) > MaxStrLen(Description) then
                                Error(StrSubstNo(DisplayNameTooLongErr, MaxStrLen(Description)));
                            Validate(Description, CopyStr(DescriptionInCurrentLanguage, 1, MaxStrLen(Description)));
                            RegisterFieldSet(FieldNo(Description));
                        end;
                    end;
                }
                field(dueDateCalculation; "Due Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'DueDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Due Date Calculation"));
                    end;
                }
                field(discountDateCalculation; "Discount Date Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountDateCalculation', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Discount Date Calculation"));
                    end;
                }
                field(discountPercent; "Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'DiscountPercent', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Discount %"));
                    end;
                }
                field(calculateDiscountOnCreditMemos; "Calc. Pmt. Disc. on Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'CalcPmtDiscOnCreditMemos', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Calc. Pmt. Disc. on Cr. Memos"));
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                field(default; Default)
                {
                    ApplicationArea = All;
                    Caption = 'default';
                    ToolTip = 'Specifies that the payment terms are the default.';

                    trigger OnValidate()
                    var
                        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
                    begin
                        if Default = false then
                            Error(CannotSetDefaultToFalseErr);

                        O365SalesInitialSetup.UpdateDefaultPaymentTerms(Code);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        Default := O365SalesInitialSetup.IsDefaultPaymentTerms(Rec);
        DescriptionInCurrentLanguage := GetDescriptionInCurrentLanguage;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        PaymentTerms.SetRange(Code, Code);
        if not PaymentTerms.IsEmpty then
            Insert;

        Insert(true);

        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        Modify(true);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
    end;

    trigger OnOpenPage()
    var
        O365PaymentTerms: Record "O365 Payment Terms";
    begin
        BindSubscription(NativeAPILanguageHandler);
        SetFilter(Code, '<>%1&<>%2', O365PaymentTerms.ExcludedOneMonthPaymentTermCode,
          O365PaymentTerms.ExcludedCurrentMonthPaymentTermCode);
    end;

    var
        TempFieldSet: Record "Field" temporary;
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        Default: Boolean;
        CannotSetDefaultToFalseErr: Label 'It is not possible to set the default to false. Select a different Payment Term as a default.';
        DescriptionInCurrentLanguage: Text;
        DisplayNameTooLongErr: Label 'The display name can be at most %1 characters long.', Comment = '%1 - Max length of display name';

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Payment Terms", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Payment Terms";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

