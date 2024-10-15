page 10736 "Customer/Vendor Warnings 349"
{
    Caption = 'Customer/Vendor Warnings 349';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Customer/Vendor Warning 349";

    layout
    {
        area(content)
        {
            repeater(Control1100000)
            {
                ShowCaption = false;
                field("Include Correction"; "Include Correction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to include the general ledger entry correction in the declaration.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line entry invoice type.';
                }
                field("Customer/Vendor Name"; "Customer/Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor name that is associated with the posted document.';
                }
                field("Customer/Vendor No."; "Customer/Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor number that is associated with the posted document.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the document was posted.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the posted document.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry was part of a third-party trade.';
                    Visible = false;
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry originates from the sale of services to other EU countries/regions.';
                    Visible = false;
                }
                field("Delivery Operation Code"; "Delivery Operation Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of export delivery for the VAT transaction.';
                }
                field("Previous Declared Amount"; "Previous Declared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declared amounts that have been posted and reported to the customer or vendor, that need to be corrected.';
                }
                field("Original Declaration FY"; "Original Declaration FY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fiscal year when the posted document was declared.';

                    trigger OnValidate()
                    begin
                        if ("Original Declaration FY" <> PrevFiscalYear) and ("Original Declaration FY" <> '') then begin
                            Rectify("Original Declaration FY", "Original Declaration Period");
                            "Original Declared Amount" := 0;
                        end else
                            "Previous Declared Amount" := 0;
                    end;
                }
                field("Original Declaration Period"; "Original Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period when the posted document was declared, such as quarterly or annually.';

                    trigger OnValidate()
                    begin
                        if ("Original Declaration Period" <> PrevPeriod) and ("Original Declaration Period" <> '') then begin
                            Rectify("Original Declaration FY", "Original Declaration Period");
                            "Original Declared Amount" := 0;
                        end else
                            "Previous Declared Amount" := 0;
                    end;
                }
                field("Original Declared Amount"; "Original Declared Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declared amounts that have been posted and reported to the customer or vendor.';

                    trigger OnValidate()
                    begin
                        if (("Original Declaration Period" <> PrevPeriod) and ("Original Declaration Period" <> '')) or
                           (("Original Declaration FY" <> PrevFiscalYear) and ("Original Declaration FY" <> ''))
                        then begin
                            if "Original Declared Amount" > "Previous Declared Amount" then
                                Error(Text1100009);
                            Rectify("Original Declaration FY", "Original Declaration Period");
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Process)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Process';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Commit the changes you have made in the report. ';

                trigger OnAction()
                var
                    PreviousFYorPeriod: Boolean;
                begin
                    PreviousFYorPeriod := false;
                    SetRange("Include Correction", true);
                    if FindFirst() then begin
                        repeat
                            if ("Original Declaration FY" > PrevFiscalYear) or
                               (("Original Declaration FY" = PrevFiscalYear) and ("Original Declaration Period" > PrevPeriod))
                            then
                                PreviousFYorPeriod := true;
                        until Next() = 0;
                        if PreviousFYorPeriod then
                            Error(Text1100006);
                    end;
                    Reset;
                    if Confirm(
                         StrSubstNo(Text1100007, FieldCaption("Include Correction"), FieldCaption("Original Declaration FY"),
                           FieldCaption("Original Declaration Period")), false)
                    then begin
                        IsProcess := true;
                        CurrPage.Close;
                    end else
                        Message(Text1100008);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if (("Original Declaration Period" <> PrevPeriod) and ("Original Declaration Period" <> '')) or
           (("Original Declaration FY" <> PrevFiscalYear) and ("Original Declaration FY" <> ''))
        then
            Rectify("Original Declaration FY", "Original Declaration Period");
    end;

    var
        Cust: Record Customer;
        Cust2: Record Customer;
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        TempPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr." temporary;
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        NoTaxableMgt: Codeunit "No Taxable Mgt.";
        Navigate: Page Navigate;
        PrevFiscalYear: Code[4];
        PrevPeriod: Code[2];
        NumFiscalYear: Integer;
        ExcludeGenProductPostingGroupFilter: Text;
        Text1100000: Label 'Incorrect Fiscal Year.';
        Text1100006: Label 'At least one of the lines marked for correction has a Fiscal Year \and Period which is not previous to current declaration period. \Please correct them before proceeding with the file generation.';
        Text1100007: Label 'Only corrections marked as "%1", and with a valid %2 and %3 will be included in the file. \Are you sure you want to continue and generate the text file?.';
        Text1100008: Label 'The process has been aborted. No file will be created.';
        IsProcess: Boolean;
        Text1100009: Label '"Original declared Amount" cannot be high than "Previous Declared Amount".';

    [Scope('OnPrem')]
    procedure Initialize(RFFiscalYear: Code[4]; RFPeriod: Code[2])
    begin
        PrevFiscalYear := RFFiscalYear;
        if StrLen(RFPeriod) = 2 then
            PrevPeriod := RFPeriod
        else
            PrevPeriod := Format(RFPeriod, 2, '<Text,2><Filler Character,0>');
    end;

    procedure SetExcludeGenProductPostingGroupFilter(FilterText: Text)
    begin
        ExcludeGenProductPostingGroupFilter := FilterText;
    end;

    [Scope('OnPrem')]
    procedure Rectify(FiscalYear: Code[4]; Period: Code[2])
    var
        VATEntry: Record "VAT Entry";
        NumPeriod: Integer;
        AmountEUService: Decimal;
        AmountOpTri: Decimal;
        NormalAmount: Decimal;
        StartDateFormula: DateFormula;
        EndDateFormula: DateFormula;
        FromDate: Date;
        ToDate: Date;
    begin
        if not Evaluate(NumFiscalYear, FiscalYear) then
            Error(Text1100000);

        case true of
            Period in
            ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']:
                begin
                    Evaluate(StartDateFormula, '<-CM>');
                    Evaluate(EndDateFormula, '<CM>');
                    Evaluate(NumPeriod, Format(Period));
                    FromDate := DMY2Date(1, NumPeriod, NumFiscalYear);
                    ToDate := CalcDate(EndDateFormula, FromDate);
                end;
            Period in ['1T', '2T', '3T', '4T']:
                begin
                    Evaluate(StartDateFormula, '<-CQ>');
                    Evaluate(EndDateFormula, '<CQ>');
                    Evaluate(NumPeriod, DelChr(Format(Period), '=', 'T'));
                    FromDate := DMY2Date(1, (NumPeriod * 3) - 2, NumFiscalYear);
                    ToDate := CalcDate(EndDateFormula, FromDate);
                end;
            Period = '0A':
                begin
                    Evaluate(StartDateFormula, '<-CY>');
                    Evaluate(EndDateFormula, '<CY>');
                    FromDate := DMY2Date(1, 1, NumFiscalYear);
                    ToDate := CalcDate(EndDateFormula, FromDate);
                end;
            else
                Error(Text1100000);
        end;

        "Previous Declared Amount" := 0;

        if Type = Type::Sale then begin
            TempSalesCrMemoHeader.DeleteAll();
            Cust.Get("Customer/Vendor No.");
            Cust2.SetRange("VAT Registration No.", Cust."VAT Registration No.");
            if Cust2.FindSet() then
                repeat
                    CalcAmountsFromVATEntries(
                      NormalAmount, AmountOpTri, AmountEUService, VATEntry.Type::Sale, Cust2."No.", FromDate, ToDate,
                      StartDateFormula, EndDateFormula);
                    NoTaxableMgt.CalcNoTaxableAmountCustomerSimple(NormalAmount, AmountEUService, AmountOpTri, Cust2."No.", FromDate, ToDate, '');
                until Cust2.Next() = 0;
        end else begin
            TempPurchCrMemoHdr.DeleteAll();
            Vendor.Get("Customer/Vendor No.");
            Vendor2.SetRange("VAT Registration No.", Vendor."VAT Registration No.");
            if Vendor2.FindSet() then
                repeat
                    CalcAmountsFromVATEntries(
                      NormalAmount, AmountOpTri, AmountEUService, VATEntry.Type::Purchase, Vendor2."No.", FromDate, ToDate,
                      StartDateFormula, EndDateFormula);
                    NoTaxableMgt.CalcNoTaxableAmountVendor(NormalAmount, AmountEUService, Vendor2."No.", FromDate, ToDate, '');
                until Vendor2.Next() = 0;
        end;
        if "EU Service" then
            "Previous Declared Amount" := AmountEUService
        else
            if "EU 3-Party Trade" then
                "Previous Declared Amount" := AmountOpTri
            else
                "Previous Declared Amount" := NormalAmount;
        if "Previous Declared Amount" < 0 then
            "Previous Declared Amount" := -"Previous Declared Amount";
    end;

    local procedure CalcAmountsFromVATEntries(var NormalAmount: Decimal; var AmountOpTri: Decimal; var AmountEUService: Decimal; EntryType: Enum "General Posting Type"; CustVendNo: Code[20]; FromDate: Date; ToDate: Date; StartDateFormula: DateFormula; EndDateFormula: DateFormula)
    var
        VATEntry: Record "VAT Entry";
    begin
        OnBeforeCalcAmountsFromVATEntries(VATEntry, Rec);
        with VATEntry do begin
            SetRange(Type, EntryType);
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetRange("Bill-to/Pay-to No.", CustVendNo);
            SetRange("Posting Date", FromDate, ToDate);
            if ExcludeGenProductPostingGroupFilter <> '' then
                SetFilter("Gen. Prod. Posting Group", ExcludeGenProductPostingGroupFilter);
            if FindSet() then
                repeat
                    if not IsCorrectiveCrMemoDiffPeriod(StartDateFormula, EndDateFormula) then
                        case true of
                            ((not "EU Service") and (not "EU 3-Party Trade")):
                                NormalAmount += Base;
                            ("EU 3-Party Trade" and (not "EU Service")):
                                AmountOpTri += Base;
                            "EU Service":
                                AmountEUService += Base;
                        end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure Cancelled() GotCancelled: Boolean
    begin
        GotCancelled := not IsProcess;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmountsFromVATEntries(VATEntry: Record "VAT Entry"; var CustomerVendorWarning349: Record "Customer/Vendor Warning 349")
    begin
    end;
}

