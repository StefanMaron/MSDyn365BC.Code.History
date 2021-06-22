page 2862 "Native - Payment Methods"
{
    Caption = 'nativePaymentMethods', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
    SourceTable = "Payment Method";

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
                            O365SalesInitialSetup.UpdateDefaultPaymentMethodFromRec(Rec);
                    end;
                }
                field(displayName; DescriptionInCurrentLanguage)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
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
                field(default; Default)
                {
                    ApplicationArea = All;
                    Caption = 'default';
                    ToolTip = 'Specifies that the payment methods are the default.';

                    trigger OnValidate()
                    var
                        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
                    begin
                        if not Default then
                            Error(CannotSetDefaultToFalseErr);

                        O365SalesInitialSetup.UpdateDefaultPaymentMethodFromRec(Rec);
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
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
        Default := O365SalesInitialSetup.IsDefaultPaymentMethod(Rec);
        DescriptionInCurrentLanguage := GetDescriptionInCurrentLanguage;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PaymentMethod: Record "Payment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        PaymentMethod.SetRange(Code, Code);
        if not PaymentMethod.IsEmpty then
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
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        BindSubscription(NativeAPILanguageHandler);

        if EnvInfoProxy.IsInvoicing then
            SetRange("Use for Invoicing", true);
    end;

    var
        TempFieldSet: Record "Field" temporary;
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        DescriptionInCurrentLanguage: Text;
        Default: Boolean;
        CannotSetDefaultToFalseErr: Label 'It is not possible to set the default to false. Select a different Payment Method as a default.';
        DisplayNameTooLongErr: Label 'The display name can be at most %1 characters long.', Comment = '%1 - Max length of display name';

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"Payment Method", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"Payment Method";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

