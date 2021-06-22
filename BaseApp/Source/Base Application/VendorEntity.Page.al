page 5472 "Vendor Entity"
{
    Caption = 'vendors', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'vendor';
    EntitySetName = 'vendors';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Vendor;

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
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Name));
                    end;
                }
                field(address; PostalAddressJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Address', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the address for the vendor.';

                    trigger OnValidate()
                    begin
                        PostalAddressSet := true;
                    end;
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'PhoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Phone No."));
                    end;
                }
                field(email; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'Email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("E-Mail"));
                    end;
                }
                field(website; "Home Page")
                {
                    ApplicationArea = All;
                    Caption = 'Website', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Home Page"));
                    end;
                }
                field(taxRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'TaxRegistrationNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("VAT Registration No."));
                    end;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'CurrencyId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Currency Id" = BlankGUID then
                            "Currency Code" := ''
                        else begin
                            Currency.SetRange(Id, "Currency Id");
                            if not Currency.FindFirst then
                                Error(CurrencyIdDoesNotMatchACurrencyErr);

                            "Currency Code" := Currency.Code;
                        end;

                        RegisterFieldSet(FieldNo("Currency Id"));
                        RegisterFieldSet(FieldNo("Currency Code"));
                    end;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'CurrencyCode', Locked = true;

                    trigger OnValidate()
                    begin
                        "Currency Code" :=
                          GraphMgtGeneralTools.TranslateCurrencyCodeToNAVCurrencyCode(
                            LCYCurrencyCode, CopyStr(CurrencyCodeTxt, 1, MaxStrLen(LCYCurrencyCode)));

                        if Currency.Code <> '' then begin
                            if Currency.Code <> "Currency Code" then
                                Error(CurrencyValuesDontMatchErr);
                            exit;
                        end;

                        if "Currency Code" = '' then
                            "Currency Id" := BlankGUID
                        else begin
                            if not Currency.Get("Currency Code") then
                                Error(CurrencyCodeDoesNotMatchACurrencyErr);

                            "Currency Id" := Currency.Id;
                        end;

                        RegisterFieldSet(FieldNo("Currency Id"));
                        RegisterFieldSet(FieldNo("Currency Code"));
                    end;
                }
                field(irs1099Code; IRS1099Code)
                {
                    ApplicationArea = All;
                    Caption = 'IRS1099Code', Locked = true;
                }
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'PaymentTermsId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Payment Terms Id" = BlankGUID then
                            "Payment Terms Code" := ''
                        else begin
                            PaymentTerms.SetRange(Id, "Payment Terms Id");
                            if not PaymentTerms.FindFirst then
                                Error(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            "Payment Terms Code" := PaymentTerms.Code;
                        end;

                        RegisterFieldSet(FieldNo("Payment Terms Id"));
                        RegisterFieldSet(FieldNo("Payment Terms Code"));
                    end;
                }
                field(paymentMethodId; "Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'PaymentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Payment Method Id" = BlankGUID then
                            "Payment Method Code" := ''
                        else begin
                            PaymentMethod.SetRange(Id, "Payment Method Id");
                            if not PaymentMethod.FindFirst then
                                Error(PaymentMethodIdDoesNotMatchAPaymentMethodErr);

                            "Payment Method Code" := PaymentMethod.Code;
                        end;

                        RegisterFieldSet(FieldNo("Payment Method Id"));
                        RegisterFieldSet(FieldNo("Payment Method Code"));
                    end;
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'TaxLiable', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Tax Liable"));
                    end;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Blocked));
                    end;
                }
                field(balance; "Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                part(picture; "Picture Entity")
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(Id);
                }
                part(defaultDimensions; "Default Dimension Entity")
                {
                    ApplicationArea = All;
                    Caption = 'DefaultDimensions', Locked = true;
                    EntityName = 'defaultDimensions';
                    EntitySetName = 'defaultDimensions';
                    SubPageLink = ParentId = FIELD(Id);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Vendor: Record Vendor;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        Vendor.SetRange("No.", "No.");
        if not Vendor.IsEmpty then
            Insert;

        Insert(true);

        ProcessPostalAddress;
        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        Modify(true);
        SetCalculatedFields;
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Vendor: Record Vendor;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        Vendor.SetRange(Id, Id);
        Vendor.FindFirst;

        ProcessPostalAddress;

        if "No." = Vendor."No." then
            Modify(true)
        else begin
            Vendor.TransferFields(Rec, false);
            Vendor.Rename("No.");
            TransferFields(Vendor);
        end;

        SetCalculatedFields;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    var
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        TempFieldSet: Record "Field" temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        PostalAddressJSON: Text;
        IRS1099Code: Code[10];
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        PaymentMethodIdDoesNotMatchAPaymentMethodErr: Label 'The "paymentMethodId" does not match to a Payment Method.', Locked = true;
        BlankGUID: Guid;
        PostalAddressSet: Boolean;

    local procedure SetCalculatedFields()
    var
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
    begin
        PostalAddressJSON := GraphMgtVendor.PostalAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(Id);
        Clear(PostalAddressJSON);
        Clear(IRS1099Code);
        Clear(PostalAddressSet);
        TempFieldSet.DeleteAll;
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::Vendor, FieldNo) then
            exit;

        TempFieldSet.Init;
        TempFieldSet.TableNo := DATABASE::Vendor;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;

    local procedure ProcessPostalAddress()
    var
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
    begin
        if not PostalAddressSet then
            exit;

        GraphMgtVendor.UpdatePostalAddress(PostalAddressJSON, Rec);

        if xRec.Address <> Address then
            RegisterFieldSet(FieldNo(Address));

        if xRec."Address 2" <> "Address 2" then
            RegisterFieldSet(FieldNo("Address 2"));

        if xRec.City <> City then
            RegisterFieldSet(FieldNo(City));

        if xRec."Country/Region Code" <> "Country/Region Code" then
            RegisterFieldSet(FieldNo("Country/Region Code"));

        if xRec."Post Code" <> "Post Code" then
            RegisterFieldSet(FieldNo("Post Code"));

        if xRec.County <> County then
            RegisterFieldSet(FieldNo(County));
    end;
}

