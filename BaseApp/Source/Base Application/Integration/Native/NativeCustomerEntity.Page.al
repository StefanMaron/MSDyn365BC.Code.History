#if not CLEAN20
page 2801 "Native - Customer Entity"
{
    Caption = 'invoicingCustomers', Locked = true;
    DelayedInsert = true;
    SourceTable = Customer;
    PageType = List;
    ODataKeyFields = SystemId;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(graphContactId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'graphContactId';
                }
                field(contactId; "Contact ID")
                {
                    ApplicationArea = All;
                    Caption = 'contactId', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the contact Id from exchange.';
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;

                    trigger OnValidate()
                    begin
                        if Name = '' then
                            Error(BlankCustomerNameErr);
                        RegisterFieldSet(FieldNo(Name));
                    end;
                }
                field(type; "Contact Type")
                {
                    ApplicationArea = All;
                    Caption = 'type', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Contact Type"));
                    end;
                }
                field(isBlocked; IsCustomerBlocked)
                {
                    ApplicationArea = All;
                    Caption = 'isBlocked', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is blocked.';
                }
                field(address; PostalAddressJSON)
                {
                    ApplicationArea = All;
                    Caption = 'address', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the address for the customer.';

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
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'TaxLiable', Locked = true;

                    trigger OnValidate()
                    begin
                        if IsUsingVAT() then
                            exit;

                        RegisterFieldSet(FieldNo("Tax Liable"));
                    end;
                }
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Tax Area ID"));
                        if IsUsingVAT() then
                            RegisterFieldSet(FieldNo("VAT Bus. Posting Group"))
                        else
                            RegisterFieldSet(FieldNo("Tax Area Code"));
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
                        RegisterFieldSet(FieldNo("VAT Registration No."));
                    end;
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
                            if not PaymentTerms.GetBySystemId(Rec."Payment Terms Id") then
                                Error(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            "Payment Terms Code" := PaymentTerms.Code;
                        end;

                        RegisterFieldSet(FieldNo("Payment Terms Id"));
                        RegisterFieldSet(FieldNo("Payment Terms Code"));
                    end;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'ShipmentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Shipment Method Id" = BlankGUID then
                            "Shipment Method Code" := ''
                        else begin
                            if not ShipmentMethod.GetBySystemId(Rec."Shipment Method Id") then
                                Error(ShipmentMethodIdDoesNotMatchAShipmentMethodErr);

                            "Shipment Method Code" := ShipmentMethod.Code;
                        end;

                        RegisterFieldSet(FieldNo("Shipment Method Id"));
                        RegisterFieldSet(FieldNo("Shipment Method Code"));
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
                            if not PaymentMethod.GetBySystemId("Payment Method Id") then
                                Error(PaymentMethodIdDoesNotMatchAPaymentMethodErr);

                            "Payment Method Code" := PaymentMethod.Code;
                        end;

                        RegisterFieldSet(FieldNo("Payment Method Id"));
                        RegisterFieldSet(FieldNo("Payment Method Code"));
                    end;
                }
                field(balance; BalanceVar)
                {
                    ApplicationArea = All;
                    Caption = 'Balance', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the customer''s balance.';
                }
                field(overdueAmount; OverdueAmount)
                {
                    ApplicationArea = All;
                    Caption = 'overdueAmount', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the amount that is overdue.';
                }
                field(totalSalesExcludingTax; SalesVar)
                {
                    ApplicationArea = All;
                    Caption = 'totalSalesExcludingTax', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the total sales excluding tax.';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                part(Coupons; "Native - Coupons")
                {
                    ApplicationArea = All;
                    Caption = 'Coupons', Locked = true;
                    SubPageLink = "Customer Id" = FIELD(SystemId);
                    EntityName = 'coupon';
                    EntitySetName = 'coupons';
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

    trigger OnDeleteRecord(): Boolean
    var
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Rec);
        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        if Name = '' then
            Error(NotProvidedCustomerNameErr);

        ProcessPostalAddress();
        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        UpdatePricesIncludingTax();

        Modify(true);

        SetCalculatedFields();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Customer: Record Customer;
    begin
        Customer.GetBySystemId(SystemId);
        ProcessPostalAddress();

        UpdatePricesIncludingTax();

        if "No." = Customer."No." then
            Modify(true)
        else begin
            Customer.TransferFields(Rec, false);
            Customer.Rename("No.");
            TransferFields(Customer);
        end;

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    trigger OnOpenPage()
    var
        EmptyIDPaymentTerms: Record "Payment Terms";
        EmptyIDPaymentMethod: Record "Payment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        EmptyGuid: Guid;
    begin
        if EmptyIDPaymentTerms.GetBySystemId(EmptyGuid) then
            GraphMgtGeneralTools.ApiSetup()
        else
            if EmptyIDPaymentMethod.GetBySystemId(EmptyGuid) then
                GraphMgtGeneralTools.ApiSetup();

        BindSubscription(NativeAPILanguageHandler);
        TranslateContactIdFilterToCustomerNoFilter();
        SelectLatestVersion();
    end;

    var
        TempFieldSet: Record "Field" temporary;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        PaymentMethod: Record "Payment Method";
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        PostalAddressJSON: Text;
        TaxAreaDisplayName: Text;
        OverdueAmount: Decimal;
        BalanceVar: Decimal;
        SalesVar: Decimal;
        BlankGUID: Guid;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        PaymentMethodIdDoesNotMatchAPaymentMethodErr: Label 'The "paymentMethodId" does not match to a Payment Method.', Locked = true;
        CannotFindCustomerErr: Label 'Cannot find the customer for the given ID.', Locked = true;
        NotProvidedCustomerNameErr: Label 'A "displayName" must be provided.', Locked = true;
        BlankCustomerNameErr: Label 'The blank "displayName" is not allowed.', Locked = true;
        PostalAddressSet: Boolean;
        IsCustomerBlocked: Boolean;

    local procedure SetCalculatedFields()
    var
        TaxAreaBuffer: Record "Tax Area Buffer";
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Rec);

        OverdueAmount := CalcOverdueBalance();
        IsCustomerBlocked := IsBlocked();

        SetRange("Date Filter", 0D, WorkDate());
        CalcFields("Sales (LCY)", "Balance (LCY)");
        BalanceVar := "Balance (LCY)";
        SalesVar := "Sales (LCY)";

        TaxAreaDisplayName := TaxAreaBuffer.GetTaxAreaDisplayName("Tax Area ID");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(TaxAreaDisplayName);
        Clear(PostalAddressJSON);
        Clear(OverdueAmount);
        Clear("Balance (LCY)");
        Clear("Sales (LCY)");
        Clear("Contact ID");
        Clear(PostalAddressSet);
        TempFieldSet.DeleteAll();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if IsFieldSet(FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::Customer;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;

    local procedure IsFieldSet(FieldNo: Integer): Boolean
    begin
        exit(TempFieldSet.Get(DATABASE::Customer, FieldNo));
    end;

    local procedure TranslateContactIdFilterToCustomerNoFilter()
    var
        NewContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
        ContactIDFilter: Text;
    begin
        ContactIDFilter := GetFilter("Contact ID");
        if ContactIDFilter <> '' then
            SetFilter("Contact ID", '')
        else begin
            ContactIDFilter := GetFilter("Contact Graph Id");
            if ContactIDFilter = '' then
                exit;

            SetFilter("Contact Graph Id", '');
        end;

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", NewContact."No.");
        if MarketingSetup.Get() then
            ContactBusinessRelation.SetRange("Business Relation Code", MarketingSetup."Bus. Rel. Code for Customers");

        if ContactBusinessRelation.FindFirst() then
            SetRange("No.", ContactBusinessRelation."No.")
        else
            Error(CannotFindCustomerErr);
    end;

    local procedure IsUsingVAT(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        exit(GeneralLedgerSetup.UseVat());
    end;

    local procedure ProcessPostalAddress()
    var
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        if not PostalAddressSet then
            exit;

        GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Rec);

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

    local procedure UpdatePricesIncludingTax()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.UseVat() then
            exit;

        Validate("Prices Including VAT", "Contact Type" = "Contact Type"::Person);
    end;
}
#endif
