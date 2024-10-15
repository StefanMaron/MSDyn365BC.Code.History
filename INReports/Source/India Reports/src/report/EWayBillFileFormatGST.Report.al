report 18036 "E-Way Bill File Format GST"
{
    Caption = 'E-Way Bill File Format';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Detailed GST Ledger Entry"; "Detailed GST Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.")
                                order(ascending)
                                where("Entry Type" = filter("Initial Entry"),
                                      Type = filter(Item | "Fixed Asset"),
                                      "GST Group Type" = filter(Goods));


            trigger OnAfterGetRecord()
            var
                DocumentNo: Code[20];
                DocumentLineNo: Integer;
                OriginalInvoiceNo: Code[20];
                ItemChargeAssgnLineNo: Integer;
            begin
                //WITH "Detailed GST Ledger Entry" do begin
                if "Detailed GST Ledger Entry".FindSet() then
                    repeat
                        if (DocumentNo <> "Document No.") or (DocumentLineNo <> "Document Line No.") or
                           (OriginalInvoiceNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                        then begin
                            ClearVariables();
                            InitializeVariables();
                            if not ServiceDoc then begin
                                GetSupplySubDocType();
                                GetGSTAmount();
                                TempExcelBuffer.NewRow();
                                TempExcelBuffer.AddColumn(SupplyType, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(SubType, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(DocType, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn("Document No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn("Posting Date", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Date);
                                TempExcelBuffer.AddColumn(GetFromOtherPartyName(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetFromGSTIN(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetFromAddress(true), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetFromAddress(false), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetPlaceState(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetPostCode(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetFromState(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetDispatchState(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToOtherPartyName(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToGSTIN(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToAddress(true), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToAddress(false), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToPlace(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToPostCode(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetToState(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetShipToState(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                if Type = Type::Item then begin
                                    TempExcelBuffer.AddColumn(Item.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                    TempExcelBuffer.AddColumn(Item.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                end else
                                    if Type = Type::"Fixed Asset" then begin
                                        TempExcelBuffer.AddColumn(FixedAsset.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                        TempExcelBuffer.AddColumn(FixedAsset.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                    end;
                                TempExcelBuffer.AddColumn("HSN/SAC Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetUOM(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(Abs(Quantity), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(Abs("GST Base Amount"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(GetTaxRate(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(Abs(CGSTAmount), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(Abs(SGSTAmount), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(Abs(IGSTAmount), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(Abs(CessAmount), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(GetTransMode(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetDistance(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                                TempExcelBuffer.AddColumn(GetTransName(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetTransID(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetVehicleNo(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                                TempExcelBuffer.AddColumn(GetVehicleType(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            end;
                        end;
                        DocumentNo := "Document No.";
                        DocumentLineNo := "Document Line No.";
                        OriginalInvoiceNo := "Original Invoice No.";
                        ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                    until Next() = 0;
            end;

            //end;
            trigger OnPostDataItem()
            begin
                CreateExcelBook();
            end;

            trigger OnPreDataItem()
            begin
                if StartDate = 0D then
                    Error(StartDateErr);
                if EndDate = 0D then
                    Error(EndDateErr);
                if (StartDate <> 0D) and (EndDate <> 0D) and (StartDate > EndDate) then
                    Error(StartDtGreaterErr);
                if LocationRegNo = '' then
                    Error(LocRegNoErr);
                if TransType = TransType::" " then
                    Error(TransTypeErr);
                if (TransType = TransType::Transfers) and (SourceNo <> '') then
                    Error(TransferSourceErr);

                SetRange("Posting Date", StartDate, EndDate);
                SetRange("Location  Reg. No.", LocationRegNo);
                case TransType of
                    TransType::Sales:
                        begin
                            SetRange("Source Type", "Source Type"::Customer);
                            if SourceNo <> '' then
                                SetRange("Source No.", SourceNo);
                            SetRange("Transaction Type", "Transaction Type"::Sales);
                        end;
                    TransType::Purchase:
                        begin
                            SetRange("Source Type", "Source Type"::Vendor);
                            if SourceNo <> '' then
                                SetRange("Source No.", SourceNo);
                            SetRange("Transaction Type", "Transaction Type"::Purchase);
                        end;
                    TransType::Transfers:
                        begin
                            SetRange("Source Type", "Source Type"::" ");
                            SetRange("Source No.", '');
                            SetRange("Transaction Type", "Transaction Type"::Sales);
                            SetRange("Original Doc. Type", "Original Doc. Type"::"Transfer Shipment");
                        end;
                end;

                MakeExcelHeader();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Start Date"; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                    }
                    field("End Date"; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                    }
                    field("Location GST Reg. No."; LocationRegNo)
                    {
                        TableRelation = "GST Registration Nos.";
                        ApplicationArea = Basic, Suite;
                        Caption = 'Location GST Reg. No.';
                    }
                    field("Transaction Type"; TransType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transaction Type';

                        trigger OnValidate()
                        begin
                            CASE TransType OF
                                TransType::Sales:
                                    SourceType := SourceType::Customer;
                                TransType::Purchase:
                                    SourceType := SourceType::Vendor;
                                TransType::Transfers:
                                    SourceType := SourceType::" ";
                            end;
                        end;
                    }
                    field("Source Type"; SourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Type';

                    }
                    field("Source No."; SourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source No.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Customer: Record Customer;
                            Vendor: Record Vendor;
                            CustomerList: Page "Customer List";
                            VendorList: Page "Vendor List";
                        begin
                            CASE SourceType OF
                                SourceType::Customer:
                                    if CustomerList.RUNMODAL() = ACTION::OK then begin
                                        CustomerList.GETRECORD(Customer);
                                        SourceNo := Customer."No.";
                                    end;
                                SourceType::Vendor:
                                    if VendorList.RUNMODAL() = ACTION::OK then begin
                                        VendorList.GETRECORD(Vendor);
                                        SourceNo := Vendor."No.";
                                    end;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }


    trigger OnPreReport()
    begin
        TempExcelBuffer.DeleteAll();
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        Location: Record "Location";
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        account: Report "Account Schedule";
        StartDate: Date;
        EndDate: Date;
        LocationRegNo: Code[15];
        SourceType: Option " ",Customer,Vendor;
        SourceNo: Code[20];
        TransType: Option " ",Sales,Purchase,Transfers;
        SupplyType: Option Inward,Outward;
        SubType: Option " ",Supply,Export,"Job Work","Recipient Not Known",Import,"Job Work Returns","Sales Returns",Others;
        DocType: Option " ","Tax Invoice","Bill of Supply","Bill of Entry","Delivery Challan","Credit Note",Others;
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        IGSTAmount: Decimal;
        CessAmount: Decimal;
        ServiceDoc: Boolean;
        StartDateErr: Label 'You must enter Start Date.';
        EndDateErr: Label 'You must enter End Date.';
        StartDtGreaterErr: Label 'You must not enter Start Date that is greater than End Date.';
        LocRegNoErr: Label 'You must enter Location Reg. No.';
        TransTypeErr: Label 'You must enter Transaction Type.';
        URPTxt: Label 'urp';
        SupplyTypeTxt: Label 'Supply Type';
        SubTypeTxt: Label 'Sub Type';
        DocTypeTxt: Label 'Doc Type';
        DocNoTxt: Label 'Doc No.';
        DocDateTxt: Label 'Doc Date';
        FromOtherPartyNameTxt: Label 'From Other Party Name';
        FromGSTINTxt: Label 'From GSTIN';
        FromAddress1Txt: Label 'From Address1';
        FromAddress2Txt: Label 'From Address 2';
        FromPlaceTxt: Label 'From Place';
        FromPinCodeTxt: Label 'From Pin Code';
        FromStateTxt: Label 'From State';
        ToOtherPartyNameTxt: Label 'To Other Party Name';
        ToGSTINTxt: Label 'To GSTIN';
        ToAddress1Txt: Label 'To Address 1';
        ToAddress2Txt: Label 'To Address 2';
        ToPlaceTxt: Label 'To Place';
        ToPinCodeTxt: Label 'To Pin Code';
        ToStateTxt: Label 'To State';
        ProductTxt: Label 'Product';
        DescriptionTxt: Label 'Description';
        HSNTxt: Label 'HSN';
        UnitTxt: Label 'Unit';
        QtyTxt: Label 'Qty';
        AssessableValueTxt: Label 'Assessable Value';
        TaxRateTxt: Label 'Tax Rate(S + C + I + Cess)';
        CGSTAmountTxt: Label 'CGST Amount';
        SGSTAmountTxt: Label 'SGST Amount';
        IGSTAmountTxt: Label 'IGST Amount';
        CessAmountTxt: Label 'CESS Amount';
        TransModeTxt: Label 'Trans Mode';
        DistaceTxt: Label 'Distance (Km)';
        TransNameTxt: Label 'Trans Name';
        TransIdTxt: Label 'Trans ID';
        TransDocNoTxt: Label 'Trans Doc No';
        TransDateTxt: Label 'Trans Date';
        VehicleNoTxt: Label 'Vehicle No.';
        DispatchStateTxt: Label 'Dispatch State';
        ShipToStateTxt: Label 'Ship To State';
        VehicleTypeTxt: Label 'Vehicle Type';
        TransferSourceErr: Label 'Source No. must be blank for transaction type:Transfer.';

    local procedure MakeExcelHeader()
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(SupplyTypeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(SubTypeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DocTypeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DocNoTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DocDateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromOtherPartyNameTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromGSTINTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromAddress1Txt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromAddress2Txt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromPlaceTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromPinCodeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(FromStateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DispatchStateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToOtherPartyNameTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToGSTINTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToAddress1Txt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToAddress2Txt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToPlaceTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToPinCodeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ToStateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ShipToStateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(ProductTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DescriptionTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(HSNTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(UnitTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(QtyTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(AssessableValueTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TaxRateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(CGSTAmountTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(SGSTAmountTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(IGSTAmountTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(CessAmountTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TransModeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(DistaceTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TransNameTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TransIdTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TransDocNoTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(TransDateTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(VehicleNoTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(VehicleTypeTxt, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure ClearVariables()
    begin
        SubType := SubType::" ";
        DocType := DocType::" ";
        ServiceDoc := false;
        CGSTAmount := 0;
        SGSTAmount := 0;
        IGSTAmount := 0;
        CessAmount := 0;
    end;

    local procedure InitializeVariables()
    var
        ServInvDoc: Boolean;
        ServCrMemoDoc: Boolean;
    begin
        with "Detailed GST Ledger Entry" do begin
            if "Source Type" = "Source Type"::Customer then
                if "Ship-to Code" <> '' then
                    ShipToAddress.Get("Source No.", "Ship-to Code")
                else
                    Customer.Get("Source No.")
            else
                if "Source Type" = "Source Type"::Vendor then
                    if "Order Address Code" <> '' then
                        OrderAddress.Get("Source No.", "Order Address Code")
                    else
                        Vendor.Get("Source No.");

            if "Source Type" = "Source Type"::Vendor then
                if "Bill to-Location(POS)" <> '' then
                    Location.Get("Bill to-Location(POS)")
                else
                    if "Location Code" <> '' then
                        Location.Get("Location Code")
                    else
                        CompanyInformation.Get();

            if "Source Type" = "Source Type"::Customer then
                if "Location Code" <> '' then
                    Location.Get("Location Code")
                else
                    CompanyInformation.Get();

            if Type = Type::Item then
                Item.Get("No.")
            else
                if Type = Type::"Fixed Asset" then
                    FixedAsset.Get("No.");

            if "Transaction Type" = "Transaction Type"::Sales then begin
                if ("Document Type" = "Document Type"::Invoice) and ServiceInvoiceHeader.Get("Document No.") then
                    ServInvDoc := true;
                if ("Document Type" = "Document Type"::"Credit Memo") and ServiceCrMemoHeader.Get("Document No.") then
                    ServCrMemoDoc := true;
                if ServInvDoc or ServCrMemoDoc then
                    ServiceDoc := true;
            end;
        end;
    end;

    local procedure GetSupplySubDocType()
    begin
        with "Detailed GST Ledger Entry" do begin
            if "Transaction Type" = "Transaction Type"::Sales then
                if "Document Type" = "Document Type"::"Credit Memo" then begin
                    SupplyType := SupplyType::Inward;
                    SubType := SubType::"Sales Returns";
                    DocType := DocType::"Credit Note";
                end else
                    if "Document Type" = "Document Type"::Invoice then begin
                        SupplyType := SupplyType::Outward;
                        case "GST Customer Type" of
                            "GST Customer Type"::Registered:
                                begin
                                    SubType := SubType::Supply;
                                    DocType := DocType::"Tax Invoice";
                                end;
                            "GST Customer Type"::Exempted:
                                begin
                                    SubType := SubType::Supply;
                                    DocType := DocType::"Bill of Supply";
                                end;
                            "GST Customer Type"::"Deemed Export", "GST Customer Type"::Export,
                            "GST Customer Type"::"SEZ Development", "GST Customer Type"::"SEZ Unit":
                                begin
                                    SubType := SubType::Export;
                                    DocType := DocType::"Tax Invoice";
                                end;
                            "GST Customer Type"::Unregistered:
                                begin
                                    SubType := SubType::"Recipient Not Known";
                                    DocType := DocType::"Tax Invoice";
                                end;
                        end;
                    end;
            if "Transaction Type" = "Transaction Type"::Purchase then
                if ("Document Type" = "Document Type"::"Credit Memo") and
                   ("GST Vendor Type" in ["GST Vendor Type"::Registered, "GST Vendor Type"::SEZ, "GST Vendor Type"::Exempted,
                                          "GST Vendor Type"::Composite, "GST Vendor Type"::Unregistered])
                then begin
                    SupplyType := SupplyType::Outward;
                    SubType := SubType::Others;
                    DocType := DocType::"Credit Note";
                end else
                    if "Document Type" = "Document Type"::Invoice then begin
                        SupplyType := SupplyType::Inward;
                        case "GST Vendor Type" of
                            "GST Vendor Type"::Registered, "GST Vendor Type"::Unregistered:
                                begin
                                    SubType := SubType::Supply;
                                    DocType := DocType::"Tax Invoice";
                                end;
                            "GST Vendor Type"::Exempted, "GST Vendor Type"::Composite:
                                begin
                                    SubType := SubType::Supply;
                                    DocType := DocType::"Bill of Supply";
                                end;
                            "GST Vendor Type"::SEZ, "GST Vendor Type"::Import:
                                begin
                                    SubType := SubType::Import;
                                    DocType := DocType::"Bill of Entry";
                                end;
                        end;
                    end;
        end;
    end;

    local procedure GetFromOtherPartyName() FromOtherPartyName: Text[50]
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                case SubType of
                    SubType::Supply, SubType::Import:
                        if "Source Type" = "Source Type"::Vendor then
                            if "Order Address Code" <> '' then
                                FromOtherPartyName := CopyStr(OrderAddress.Name, 1, 50)
                            else
                                FromOtherPartyName := CopyStr(Vendor.Name, 1, 50);
                    SubType::"Sales Returns":
                        if "Source Type" = "Source Type"::Customer then
                            if "Ship-to Code" <> '' then
                                FromOtherPartyName := CopyStr(ShipToAddress.Name, 1, 50)
                            else
                                FromOtherPartyName := CopyStr(Customer.Name, 1, 50);
                end;
            if SupplyType = SupplyType::Outward then
                if SubType in [SubType::Supply, SubType::Export, SubType::"Recipient Not Known", SubType::Others] then
                    if "Source Type" = "Source Type"::" " then begin
                        TransferShipmentHeader.Get("Document No.");
                        Location.Get(TransferShipmentHeader."Transfer-from Code");
                        FromOtherPartyName := CopyStr(Location.Name, 1, 50);
                    end else
                        if "Location Code" <> '' then
                            FromOtherPartyName := CopyStr(Location.Name, 1, 50)
                        else
                            FromOtherPartyName := CopyStr(CompanyInformation.Name, 1, 50);
        end;
    end;

    local procedure GetFromGSTIN() FromGSTIN: Code[15]
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Inward then
                if "GST Vendor Type" = "GST Vendor Type"::Unregistered then
                    FromGSTIN := URPTxt
                else
                    if "GST Customer Type" = "GST Customer Type"::Unregistered then
                        FromGSTIN := URPTxt
                    else
                        FromGSTIN := CopyStr("Buyer/Seller Reg. No.", 1, 15)
            else
                FromGSTIN := CopyStr("Location  Reg. No.", 1, 15);
    end;

    local procedure GetFromAddress(Address1: Boolean) FromAddress: Text[50]
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Inward then
                case SubType of
                    SubType::Supply, SubType::Import:
                        if "Source Type" = "Source Type"::Vendor then
                            if "Order Address Code" <> '' then
                                if Address1 then
                                    FromAddress := CopyStr(OrderAddress.Address, 1, 50)
                                else
                                    FromAddress := OrderAddress."Address 2"
                            else
                                if Address1 then
                                    FromAddress := CopyStr(Vendor.Address, 1, 50)
                                else
                                    FromAddress := Vendor."Address 2";
                    SubType::"Sales Returns":
                        if "Source Type" = "Source Type"::Customer then
                            if "Ship-to Code" <> '' then
                                if Address1 then
                                    FromAddress := CopyStr(ShipToAddress.Address, 1, 50)
                                else
                                    FromAddress := ShipToAddress."Address 2"
                            else
                                if Address1 then
                                    FromAddress := CopyStr(Customer.Address, 1, 50)
                                else
                                    FromAddress := Customer."Address 2"

                        else
                            if SubType in [SubType::Supply, SubType::Export, SubType::"Recipient Not Known", SubType::Others] then
                                if "Source Type" = "Source Type"::" " then begin
                                    TransferShipmentHeader.Get("Document No.");
                                    Location.Get(TransferShipmentHeader."Transfer-from Code");
                                    if Address1 then
                                        FromAddress := CopyStr(Location.Address, 1, 50)
                                    else
                                        FromAddress := Location."Address 2";
                                end else
                                    if "Location Code" <> '' then
                                        if Address1 then
                                            FromAddress := CopyStr(Location.Address, 1, 50)
                                        else
                                            FromAddress := Location."Address 2"
                                    else
                                        if Address1 then
                                            FromAddress := CopyStr(CompanyInformation.Address, 1, 50)
                                        else
                                            FromAddress := CompanyInformation."Address 2";
                end;
    end;

    local procedure GetPlaceState() FromPlace: Text[30]
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Inward then
                case SubType of
                    SubType::Supply, SubType::Import:
                        if "Source Type" = "Source Type"::Vendor then
                            if "Order Address Code" <> '' then
                                FromPlace := OrderAddress.City
                            else
                                FromPlace := Vendor.City;
                    SubType::"Sales Returns":
                        if "Source Type" = "Source Type"::Customer then
                            if "Ship-to Code" <> '' then
                                FromPlace := ShipToAddress.City
                            else
                                FromPlace := Customer.City;

                    else
                        if SubType in [SubType::Supply, SubType::Export, SubType::"Recipient Not Known", SubType::Others] then
                            if "Source Type" = "Source Type"::" " then begin
                                TransferShipmentHeader.Get("Document No.");
                                Location.Get(TransferShipmentHeader."Transfer-from Code");
                                FromPlace := Location.City;
                            end else
                                if "Location Code" <> '' then
                                    FromPlace := Location.City
                                else
                                    FromPlace := CompanyInformation.City;
                end;
    end;

    local procedure GetPostCode() FromPostCode: Code[20]
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Inward then
                case SubType of
                    SubType::Supply, SubType::Import:
                        if "Source Type" = "Source Type"::Vendor then
                            if "Order Address Code" <> '' then
                                FromPostCode := OrderAddress."Post Code"
                            else
                                FromPostCode := Vendor."Post Code";
                    SubType::"Sales Returns":
                        if "Source Type" = "Source Type"::Customer then
                            if "Ship-to Code" <> '' then
                                FromPostCode := ShipToAddress."Post Code"
                            else
                                FromPostCode := Customer."Post Code";
                    else
                        if SubType in [SubType::Supply, SubType::Export, SubType::"Recipient Not Known", SubType::Others] then
                            if "Source Type" = "Source Type"::" " then begin
                                TransferShipmentHeader.Get("Document No.");
                                Location.Get(TransferShipmentHeader."Transfer-from Code");
                                FromPostCode := Location."Post Code";
                            end else
                                if "Location Code" <> '' then
                                    FromPostCode := Location."Post Code"
                                else
                                    FromPostCode := CompanyInformation."Post Code";
                end;
    end;

    local procedure GetFromState() FromState: Text[50]
    var
        ShipToAdd: Record "Ship-to Address";
        State: Record State;
        FromStateCode: Code[10];
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                case SubType of
                    SubType::Supply:
                        FromStateCode := "Buyer/Seller State Code";
                    SubType::"Sales Returns":
                        if "Ship-to Code" <> '' then
                            if "GST Customer Type" in ["GST Customer Type"::"Deemed Export", "GST Customer Type"::"SEZ Development",
                                                       "GST Customer Type"::"SEZ Unit"]
                            then begin
                                ShipToAddress.Get("Source No.", "Ship-to Code");
                                FromStateCode := ShipToAdd.State;
                            end else
                                FromStateCode := "Shipping Address State Code"
                        else
                            if "GST Customer Type" in ["GST Customer Type"::"Deemed Export", "GST Customer Type"::"SEZ Development",
                                                       "GST Customer Type"::"SEZ Unit"]
                            then begin
                                Customer.Get("Source No.");
                                FromStateCode := Customer."State Code";
                            end else
                                FromStateCode := "Buyer/Seller State Code";
                end
            else
                if SubType in [SubType::Supply, SubType::Export, SubType::"Recipient Not Known", SubType::Others] then
                    FromStateCode := "Location State Code";
            if State.Get(FromStateCode) then
                FromState := State.Description;
        end;
    end;

    local procedure GetToOtherPartyName() ToOtherPartyName: Text[50]
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                if SubType in [SubType::Supply, SubType::Import, SubType::"Sales Returns"] then
                    if "Location Code" <> '' then
                        ToOtherPartyName := CopyStr(Location.Name, 1, 50)
                    else
                        ToOtherPartyName := CopyStr(CompanyInformation.Name, 1, 50);
            if SupplyType = SupplyType::Outward then
                case SubType of
                    SubType::Supply, SubType::Export, SubType::"Recipient Not Known":
                        if "Source Type" = "Source Type"::Customer then
                            if "Ship-to Code" <> '' then
                                ToOtherPartyName := CopyStr(ShipToAddress.Name, 1, 50)
                            else
                                ToOtherPartyName := CopyStr(Customer.Name, 1, 50)
                        else
                            if "Source Type" = "Source Type"::" " then begin
                                TransferShipmentHeader.Get("Document No.");
                                Location.Get(TransferShipmentHeader."Transfer-to Code");
                                ToOtherPartyName := CopyStr(Location.Name, 1, 50)
                            end;
                    SubType::Others:
                        if "Source Type" = "Source Type"::Vendor then
                            if "Order Address Code" <> '' then
                                ToOtherPartyName := CopyStr(OrderAddress.Name, 1, 50)
                            else
                                ToOtherPartyName := CopyStr(Vendor.Name, 1, 50);
                end;
        end;
    end;

    local procedure GetToGSTIN() ToGSTIN: Code[15]
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Inward then
                ToGSTIN := CopyStr("Location  Reg. No.", 1, 15)
            else
                case SubType of
                    SubType::Supply, SubType::Export:
                        ToGSTIN := CopyStr("Buyer/Seller Reg. No.", 1, 15);
                    SubType::"Recipient Not Known":
                        ToGSTIN := URPTxt;
                    SubType::Others:
                        if "GST Vendor Type" = "GST Vendor Type"::Unregistered then
                            ToGSTIN := URPTxt
                        else
                            ToGSTIN := CopyStr("Buyer/Seller Reg. No.", 1, 15);
                end;
    end;

    local procedure GetToAddress(ToAddress1: Boolean) ToAddress: Text[50]
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                if SubType in [SubType::Supply, SubType::Import, SubType::"Sales Returns"] then
                    if "Location Code" <> '' then
                        if ToAddress1 then
                            ToAddress := CopyStr(Location.Address, 1, 50)
                        else
                            ToAddress := CopyStr(Location."Address 2", 1, 50)
                    else
                        if ToAddress1 then
                            ToAddress := CopyStr(CompanyInformation.Address, 1, 50)
                        else
                            ToAddress := CompanyInformation."Address 2";
            if SupplyType = SupplyType::Outward then
                case SubType of
                    SubType::Supply, SubType::Export, SubType::"Recipient Not Known":
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            Location.Get(TransferShipmentHeader."Transfer-to Code");
                            if ToAddress1 then
                                ToAddress := CopyStr(Location.Address, 1, 50)
                            else
                                ToAddress := CopyStr(Location."Address 2", 1, 50)
                        end else
                            if "Ship-to Code" <> '' then
                                if ToAddress1 then
                                    ToAddress := CopyStr(ShipToAddress.Address, 1, 50)
                                else
                                    ToAddress := ShipToAddress."Address 2"
                            else
                                if ToAddress1 then
                                    ToAddress := CopyStr(Customer.Address, 1, 50)
                                else
                                    ToAddress := Customer."Address 2";
                    SubType::Others:
                        if "Order Address Code" <> '' then
                            if ToAddress1 then
                                ToAddress := CopyStr(OrderAddress.Address, 1, 50)
                            else
                                ToAddress := OrderAddress."Address 2"
                        else
                            if ToAddress1 then
                                ToAddress := CopyStr(Vendor.Address, 1, 50)
                            else
                                ToAddress := Vendor."Address 2";
                end;
        end;
    end;

    local procedure GetToPlace() ToPlace: Text[30]
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                if SubType in [SubType::Supply, SubType::Import, SubType::"Sales Returns"] then
                    if "Location Code" <> '' then
                        ToPlace := Location.City
                    else
                        ToPlace := CompanyInformation.City;
            if SupplyType = SupplyType::Outward then
                case SubType of
                    SubType::Supply, SubType::Export, SubType::"Recipient Not Known":
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            Location.Get(TransferShipmentHeader."Transfer-to Code");
                            ToPlace := Location.City;
                        end else
                            if "Ship-to Code" <> '' then
                                ToPlace := ShipToAddress.City
                            else
                                ToPlace := Customer.City;
                    SubType::Others:
                        if "Order Address Code" <> '' then
                            ToPlace := OrderAddress.City
                        else
                            ToPlace := Vendor.City;
                end;
        end;
    end;

    local procedure GetToPostCode() ToPostCode: Code[20]
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                if SubType in [SubType::Supply, SubType::Import, SubType::"Sales Returns"] then
                    if "Location Code" <> '' then
                        ToPostCode := Location."Post Code"
                    else
                        ToPostCode := CompanyInformation."Post Code";
            if SupplyType = SupplyType::Outward then
                case SubType of
                    SubType::Supply, SubType::Export, SubType::"Recipient Not Known":
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            Location.Get(TransferShipmentHeader."Transfer-to Code");
                            ToPostCode := Location."Post Code";
                        end else
                            if "Ship-to Code" <> '' then
                                ToPostCode := ShipToAddress."Post Code"
                            else
                                ToPostCode := Customer."Post Code";
                    SubType::Others:
                        if "Order Address Code" <> '' then
                            ToPostCode := OrderAddress."Post Code"
                        else
                            ToPostCode := Vendor."Post Code";
                end;
        end;
    end;

    local procedure GetToState() ToState: Text[50]
    var
        State: Record State;
        ToStateCode: Code[10];
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Inward then
                if SubType in [SubType::Supply, SubType::"Sales Returns"] then
                    ToStateCode := "Location State Code"
                else
                    if SubType = SubType::Import then
                        ToStateCode := '';
            if SupplyType = SupplyType::Outward then
                case SubType of
                    SubType::Supply, SubType::"Recipient Not Known", SubType::Others:
                        if "Ship-to Code" <> '' then
                            ToStateCode := "Shipping Address State Code"
                        else
                            ToStateCode := "Buyer/Seller State Code";
                    SubType::Export:
                        if "Ship-to Code" <> '' then begin
                            ShipToAddress.Get("Source No.", "Ship-to Code");
                            ToStateCode := ShipToAddress.State;
                        end else begin
                            Customer.Get("Source No.");
                            ToStateCode := Customer."State Code";
                        end;
                end;
            if State.Get(ToStateCode) then
                ToState := State.Description;
        end;
    end;

    local procedure GetUOM() UOMDesc: Text[10]
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        UnitOfMeasure: Record "Unit of Measure";
        TransferShipmentLine: Record "Transfer Shipment Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        with "Detailed GST Ledger Entry" do
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then
                    if "Source Type" = "Source Type"::Customer then begin
                        if SalesInvoiceLine.Get("Document No.", "Document Line No.") then
                            if UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code") then
                                UOMDesc := CopyStr(UnitOfMeasure.Description, 1, 10)
                    end else
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentLine.Get("Document No.", "Document Line No.");
                            if UnitOfMeasure.Get(TransferShipmentLine."Unit of Measure Code") then
                                UOMDesc := CopyStr(UnitOfMeasure.Description, 1, 10)
                        end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoLine.Get("Document No.", "Document Line No.") then
                        if UnitOfMeasure.Get(SalesCrMemoLine."Unit of Measure Code") then
                            UOMDesc := CopyStr(UnitOfMeasure.Description, 1, 10);
            end else
                if "Transaction Type" = "Transaction Type"::Purchase then
                    if "Document Type" = "Document Type"::Invoice then begin
                        PurchInvLine.Get("Document No.", "Document Line No.");
                        if UnitOfMeasure.Get(PurchInvLine."Unit of Measure Code") then
                            UOMDesc := CopyStr(UnitOfMeasure.Description, 1, 10);
                    end else
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            PurchCrMemoLine.Get("Document No.", "Document Line No.");
                            if UnitOfMeasure.Get(PurchCrMemoLine."Unit of Measure Code") then
                                UOMDesc := CopyStr(UnitOfMeasure.Description, 1, 10);
                        end;
    end;

    local procedure GetTaxRate() TaxRate: Text[12]
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTComponent: Record "GST Component";
        CGSTTaxRate: Decimal;
        SGSTTaxRate: Decimal;
        IGSTTaxRate: Decimal;
        CessTaxRate: Decimal;
    begin
        with "Detailed GST Ledger Entry" do begin
            DetailedGSTLedgerEntry.SetRange("Document Type", "Document Type");
            DetailedGSTLedgerEntry.SetRange("Document No.", "Document No.");
            DetailedGSTLedgerEntry.SetRange("Document Line No.", "Document Line No.");
            if DetailedGSTLedgerEntry.FindSet() then
                repeat
                    GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code");
                // if GSTComponent."Report View" = GSTComponent."Report View"::"SGST / UTGST" then
                //     SGSTTaxRate := DetailedGSTLedgerEntry."GST %"
                // else
                //     if GSTComponent."Report View" = GSTComponent."Report View"::CGST then
                //         CGSTTaxRate := DetailedGSTLedgerEntry."GST %"
                //     else
                //         if GSTComponent."Report View" = GSTComponent."Report View"::IGST then
                //             IGSTTaxRate := DetailedGSTLedgerEntry."GST %"
                //         else
                //             if GSTComponent."Report View" = GSTComponent."Report View"::CESS then
                //                 CessTaxRate := DetailedGSTLedgerEntry."GST %";
                // TaxRate :=
                //   FORMAT(CGSTTaxRate) + '+' + FORMAT(IGSTTaxRate) + '+' + FORMAT(CessTaxRate);
                until DetailedGSTLedgerEntry.Next() = 0;
        end;
    end;

    local procedure GetGSTAmount()
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTComponent: Record "GST Component";
    begin
        with "Detailed GST Ledger Entry" do begin
            DetailedGSTLedgerEntry.SetRange("Document Type", "Document Type");
            DetailedGSTLedgerEntry.SetRange("Document No.", "Document No.");
            DetailedGSTLedgerEntry.SetRange("Document Line No.", "Document Line No.");
            if DetailedGSTLedgerEntry.FindSet() then
                repeat
                    GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code");
                // if GSTComponent."Report View" = GSTComponent."Report View"::CESS then
                //     CessAmount := DetailedGSTLedgerEntry."GST Amount"
                // else
                //     if GSTComponent."Report View" = GSTComponent."Report View"::CGST then
                //         CGSTAmount := DetailedGSTLedgerEntry."GST Amount"
                //     else
                //         if GSTComponent."Report View" = GSTComponent."Report View"::IGST then
                //             IGSTAmount := DetailedGSTLedgerEntry."GST Amount"
                //         else
                //             if GSTComponent."Report View" = GSTComponent."Report View"::"SGST / UTGST" then
                //                 SGSTAmount := DetailedGSTLedgerEntry."GST Amount";
                until DetailedGSTLedgerEntry.Next() = 0;
        end;
    end;

    local procedure GetTransMode() TransMode: Text[50]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TransportMethod: Record "Transport Method";
    begin

    end;

    local procedure GetDistance(): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TransferShipmentHead: Record "Transfer Shipment Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with "Detailed GST Ledger Entry" do begin
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then begin
                    if "Source Type" = "Source Type"::Customer then
                        if SalesInvoiceHeader.Get("Document No.") then
                            exit(SalesInvoiceHeader."Distance (Km)");
                    if "Source Type" = "Source Type"::" " then
                        if TransferShipmentHead.Get("Document No.") then
                            exit(TransferShipmentHead."Distance (Km)");
                end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        exit(SalesCrMemoHeader."Distance (Km)");
            end;
            if "Transaction Type" = "Transaction Type"::Purchase then begin
                if "Document Type" = "Document Type"::Invoice then
                    if PurchInvHeader.Get("Document No.") then
                        exit(PurchInvHeader."Distance (Km)");
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if PurchCrMemoHdr.Get("Document No.") then
                        exit(PurchCrMemoHdr."Distance (Km)");
            end;
        end;
    end;

    local procedure GetTransName() TransName: Text[50]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TransferShipmentHead: Record "Transfer Shipment Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ShippingAgent: Record "Shipping Agent";
    begin
        with "Detailed GST Ledger Entry" do
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then
                    if "Source Type" = "Source Type"::Customer then begin
                        if SalesInvoiceHeader.Get("Document No.") then
                            if ShippingAgent.Get(SalesInvoiceHeader."Shipping Agent Code") then
                                TransName := ShippingAgent.Name;
                    end else
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            if ShippingAgent.Get(TransferShipmentHeader."Shipping Agent Code") then
                                TransName := ShippingAgent.Name;
                        end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        //if ShippingAgent.Get(SalesCrMemoHeader."Shipping Agent Code") then
                        TransName := ShippingAgent.Name;
            end else
                if "Transaction Type" = "Transaction Type"::Purchase then
                    if "Document Type" = "Document Type"::Invoice then begin
                        PurchInvHeader.Get("Document No.");
                        if ShippingAgent.Get(PurchInvHeader."Shipping Agent Code") then
                            TransName := ShippingAgent.Name;
                    end else
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            PurchCrMemoHdr.Get("Document No.");
                            if ShippingAgent.Get(PurchCrMemoHdr."Shipping Agent Code") then
                                TransName := ShippingAgent.Name;
                        end;
    end;

    local procedure GetTransID() TransID: Code[15]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TransferShipmentHead: Record "Transfer Shipment Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ShippingAgent: Record "Shipping Agent";
    begin
        with "Detailed GST Ledger Entry" do
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then
                    if "Source Type" = "Source Type"::Customer then begin
                        if SalesInvoiceHeader.Get("Document No.") then
                            if ShippingAgent.Get(SalesInvoiceHeader."Shipping Agent Code") then
                                TransID := CopyStr(ShippingAgent."GST Registration No.", 1, 15);
                    end else
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            if ShippingAgent.Get(TransferShipmentHead."Shipping Agent Code") then
                                TransID := CopyStr(ShippingAgent."GST Registration No.", 1, 15);
                        end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        TransID := CopyStr(ShippingAgent."GST Registration No.", 1, 15)
            end else
                if "Transaction Type" = "Transaction Type"::Purchase then
                    if "Document Type" = "Document Type"::Invoice then begin
                        PurchInvHeader.Get("Document No.");
                        if ShippingAgent.Get(PurchInvHeader."Shipping Agent Code") then
                            TransID := CopyStr(ShippingAgent."GST Registration No.", 1, 15);
                    end else
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            PurchCrMemoHdr.Get("Document No.");
                            if ShippingAgent.Get(PurchCrMemoHdr."Shipping Agent Code") then
                                TransID := CopyStr(ShippingAgent."GST Registration No.", 1, 15);
                        end;
    end;

    local procedure GetVehicleNo() VehicleNo: Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TransferShipmentHead: Record "Transfer Shipment Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with "Detailed GST Ledger Entry" do
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then
                    if "Source Type" = "Source Type"::Customer then begin
                        if SalesInvoiceHeader.Get("Document No.") then
                            VehicleNo := SalesInvoiceHeader."Vehicle No.";
                    end else
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            VehicleNo := TransferShipmentHeader."Vehicle No.";
                        end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        VehicleNo := SalesCrMemoHeader."Vehicle No.";
            end else
                if "Transaction Type" = "Transaction Type"::Purchase then
                    if "Document Type" = "Document Type"::Invoice then begin
                        PurchInvHeader.Get("Document No.");
                        VehicleNo := PurchInvHeader."Vehicle No.";
                    end else
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            PurchCrMemoHdr.Get("Document No.");
                            VehicleNo := PurchCrMemoHdr."Vehicle No.";
                        end;
    end;

    local procedure GetDispatchState() DispatchState: Text[50]
    var
        PurchaseHead: Record "Purchase Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        State: Record State;
    begin
        with "Detailed GST Ledger Entry" do
            if SupplyType = SupplyType::Outward then
                if SubType in [SubType::Supply, SubType::"Recipient Not Known"] then begin
                    SalesInvoiceLine.SetRange("Document No.", "Document No.");
                    SalesInvoiceLine.SetRange("Drop Shipment", true);
                    if SalesInvoiceLine.FindFirst() then begin
                        PurchaseHead.SetRange("No.", SalesInvoiceLine."Order No.");
                        if PurchaseHead.FindFirst() then
                            if State.Get(PurchaseHead.State) then
                                DispatchState := State.Description;
                    end;
                end;
    end;

    local procedure GetShipToState() ShipToState: Text[50]
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        State: Record State;
        ShipToStateCode: Code[10];
    begin
        with "Detailed GST Ledger Entry" do begin
            if SupplyType = SupplyType::Outward then
                if SubType in [SubType::Supply, SubType::"Recipient Not Known"] then begin
                    SalesInvoiceLine.SetRange("Document No.", "Document No.");
                    SalesInvoiceLine.SetRange("Drop Shipment", true);
                    if SalesInvoiceLine.FindFirst() then begin
                        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
                        if SalesInvoiceHeader."Ship-to Code" <> '' then
                            ShipToStateCode := SalesInvoiceHeader."GST Ship-to State Code"
                        else
                            ShipToStateCode := SalesInvoiceHeader."GST Bill-to State Code"
                    end;
                end;
            if State.Get(ShipToStateCode) then
                ShipToState := State.Description;
        end;
    end;

    local procedure GetVehicleType() VehicleType: Text[10]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TransferShipmentHead: Record "Transfer Shipment Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        with "Detailed GST Ledger Entry" do
            if "Transaction Type" = "Transaction Type"::Sales then begin
                if "Document Type" = "Document Type"::Invoice then
                    if "Source Type" = "Source Type"::Customer then begin
                        if SalesInvoiceHeader.Get("Document No.") then
                            VehicleType := Format(SalesInvoiceHeader."Vehicle Type");
                    end else
                        if "Source Type" = "Source Type"::" " then begin
                            TransferShipmentHeader.Get("Document No.");
                            VehicleType := Format(TransferShipmentHead."Vehicle Type");
                        end;
                if "Document Type" = "Document Type"::"Credit Memo" then
                    if SalesCrMemoHeader.Get("Document No.") then
                        VehicleType := Format(SalesCrMemoHeader."Vehicle Type");
            end else
                if "Transaction Type" = "Transaction Type"::Purchase then
                    if "Document Type" = "Document Type"::Invoice then begin
                        PurchInvHeader.Get("Document No.");
                        VehicleType := Format(PurchInvHeader."Vehicle Type");
                    end else
                        if "Document Type" = "Document Type"::"Credit Memo" then begin
                            PurchCrMemoHdr.Get("Document No.");
                            VehicleType := Format(PurchCrMemoHdr."Vehicle Type");
                        end;
    end;

    local procedure CreateExcelBook()
    begin
        TempExcelBuffer.CreateNewBook('eway');
        TempExcelBuffer.WriteSheet('eway', CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.OpenExcel();
    end;
}