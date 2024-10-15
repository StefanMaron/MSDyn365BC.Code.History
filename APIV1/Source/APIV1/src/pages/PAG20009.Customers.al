page 20009 "APIV1 - Customers"
{
    APIVersion = 'v1.0';
    Caption = 'customers', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'customer';
    EntitySetName = 'customers';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 18;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        IF Name = '' THEN
                            ERROR(BlankCustomerNameErr);
                        RegisterFieldSet(FIELDNO(Name));
                    end;
                }
                field(type; "Contact Type")
                {
                    ApplicationArea = All;
                    Caption = 'type', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Contact Type"));
                    end;
                }
                field(address; PostalAddressJSON)
                {
                    ApplicationArea = All;
                    Caption = 'address', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the address for the customer.';

                    trigger OnValidate()
                    begin
                        PostalAddressSet := TRUE;
                    end;
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Phone No."));
                    end;
                }
                field(email; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("E-Mail"));
                    end;
                }
                field(website; "Home Page")
                {
                    ApplicationArea = All;
                    Caption = 'website', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Home Page"));
                    end;
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'taxLiable', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Tax Liable"));
                    end;
                }
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId', Locked = true;

                    trigger OnValidate()
                    var
                        GeneralLedgerSetup: Record "General Ledger Setup";
                    begin
                        RegisterFieldSet(FIELDNO("Tax Area ID"));

                        IF NOT GeneralLedgerSetup.UseVat() THEN
                            RegisterFieldSet(FIELDNO("Tax Area Code"))
                        ELSE
                            RegisterFieldSet(FIELDNO("VAT Bus. Posting Group"));
                    end;
                }
                field(taxAreaDisplayName; TaxAreaDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaDisplayName', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the display name of the tax area.';
                }
                field(taxRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'taxRegistrationNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("VAT Registration No."));
                    end;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'currencyId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Currency Id" = BlankGUID THEN
                            "Currency Code" := ''
                        ELSE BEGIN
                            Currency.SETRANGE(Id, "Currency Id");
                            IF NOT Currency.FINDFIRST() THEN
                                ERROR(CurrencyIdDoesNotMatchACurrencyErr);

                            "Currency Code" := Currency.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Currency Id"));
                        RegisterFieldSet(FIELDNO("Currency Code"));
                    end;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;

                    trigger OnValidate()
                    begin
                        "Currency Code" :=
                          GraphMgtGeneralTools.TranslateCurrencyCodeToNAVCurrencyCode(
                            LCYCurrencyCode, COPYSTR(CurrencyCodeTxt, 1, MAXSTRLEN(LCYCurrencyCode)));

                        IF Currency.Code <> '' THEN BEGIN
                            IF Currency.Code <> "Currency Code" THEN
                                ERROR(CurrencyValuesDontMatchErr);
                            EXIT;
                        END;

                        IF "Currency Code" = '' THEN
                            "Currency Id" := BlankGUID
                        ELSE BEGIN
                            IF NOT Currency.GET("Currency Code") THEN
                                ERROR(CurrencyCodeDoesNotMatchACurrencyErr);

                            "Currency Id" := Currency.Id;
                        END;

                        RegisterFieldSet(FIELDNO("Currency Id"));
                        RegisterFieldSet(FIELDNO("Currency Code"));
                    end;
                }
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentTermsId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Payment Terms Id" = BlankGUID THEN
                            "Payment Terms Code" := ''
                        ELSE BEGIN
                            PaymentTerms.SETRANGE(Id, "Payment Terms Id");
                            IF NOT PaymentTerms.FINDFIRST() THEN
                                ERROR(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            "Payment Terms Code" := PaymentTerms.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Payment Terms Id"));
                        RegisterFieldSet(FIELDNO("Payment Terms Code"));
                    end;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'shipmentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Shipment Method Id" = BlankGUID THEN
                            "Shipment Method Code" := ''
                        ELSE BEGIN
                            ShipmentMethod.SETRANGE(Id, "Shipment Method Id");
                            IF NOT ShipmentMethod.FINDFIRST() THEN
                                ERROR(ShipmentMethodIdDoesNotMatchAShipmentMethodErr);

                            "Shipment Method Code" := ShipmentMethod.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Shipment Method Id"));
                        RegisterFieldSet(FIELDNO("Shipment Method Code"));
                    end;
                }
                field(paymentMethodId; "Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Payment Method Id" = BlankGUID THEN
                            "Payment Method Code" := ''
                        ELSE BEGIN
                            PaymentMethod.SETRANGE(Id, "Payment Method Id");
                            IF NOT PaymentMethod.FINDFIRST() THEN
                                ERROR(PaymentMethodIdDoesNotMatchAPaymentMethodErr);

                            "Payment Method Code" := PaymentMethod.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Payment Method Id"));
                        RegisterFieldSet(FIELDNO("Payment Method Code"));
                    end;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'blocked', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Blocked));
                    end;
                }
                part(customerFinancialDetails; 20048)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Financial Details', Locked = true;
                    EntityName = 'customerFinancialDetail';
                    EntitySetName = 'customerFinancialDetails';
                    SubPageLink = Id = FIELD(Id);
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
                part(picture; 5468)
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(Id);
                }
                part(defaultDimensions; 5509)
                {
                    ApplicationArea = All;
                    Caption = 'Default Dimensions', Locked = true;
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
        SetCalculatedFields();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Customer: Record Customer;
        RecRef: RecordRef;
    begin
        IF Name = '' THEN
            ERROR(NotProvidedCustomerNameErr);

        Customer.SETRANGE("No.", "No.");
        IF NOT Customer.ISEMPTY() THEN
            INSERT();

        INSERT(TRUE);

        ProcessPostalAddress();

        RecRef.GETTABLE(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        MODIFY(TRUE);
        SetCalculatedFields();
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Customer: Record Customer;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.Id <> Id THEN
            GraphMgtGeneralTools.ErrorIdImmutable();

        Customer.SETRANGE(Id, Id);
        Customer.FINDFIRST();

        ProcessPostalAddress();

        IF "No." = Customer."No." THEN
            MODIFY(TRUE)
        ELSE BEGIN
            Customer.TRANSFERFIELDS(Rec, FALSE);
            Customer.RENAME("No.");
            TRANSFERFIELDS(Customer);
        END;

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    var
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        PaymentMethod: Record "Payment Method";
        TempFieldSet: Record 2000000041 temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        PostalAddressJSON: Text;
        TaxAreaDisplayName: Text;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        PaymentMethodIdDoesNotMatchAPaymentMethodErr: Label 'The "paymentMethodId" does not match to a Payment Method.', Locked = true;
        BlankGUID: Guid;
        NotProvidedCustomerNameErr: Label 'A "displayName" must be provided.', Locked = true;
        BlankCustomerNameErr: Label 'The blank "displayName" is not allowed.', Locked = true;
        PostalAddressSet: Boolean;

    local procedure SetCalculatedFields()
    var
        TaxAreaBuffer: Record "Tax Area Buffer";
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
        TaxAreaDisplayName := TaxAreaBuffer.GetTaxAreaDisplayName("Tax Area ID");
    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(Id);
        CLEAR(TaxAreaDisplayName);
        CLEAR(PostalAddressJSON);
        CLEAR(PostalAddressSet);
        TempFieldSet.DELETEALL();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::Customer, FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::Customer;
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;

    local procedure ProcessPostalAddress()
    var
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        IF NOT PostalAddressSet THEN
            EXIT;

        GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Rec);

        IF xRec.Address <> Address THEN
            RegisterFieldSet(FIELDNO(Address));

        IF xRec."Address 2" <> "Address 2" THEN
            RegisterFieldSet(FIELDNO("Address 2"));

        IF xRec.City <> City THEN
            RegisterFieldSet(FIELDNO(City));

        IF xRec."Country/Region Code" <> "Country/Region Code" THEN
            RegisterFieldSet(FIELDNO("Country/Region Code"));

        IF xRec."Post Code" <> "Post Code" THEN
            RegisterFieldSet(FIELDNO("Post Code"));

        IF xRec.County <> County THEN
            RegisterFieldSet(FIELDNO(County));
    end;
}

