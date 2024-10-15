report 12193 "Export VAT Transactions"
{
    Caption = 'Export VAT Transactions';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
            DataItemTableView = SORTING("No.");
            dataitem(DetailedRecords; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                dataitem(FEInvoicesIssued; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('FE'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessFEInvoicesIssued;
                    end;
                }
                dataitem(FRInvoicesReceived; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('FR'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessFRInvoicesReceived;
                    end;
                }
                dataitem(NECreditMemoIssued; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('NE'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessNECreditMemoIssued;
                    end;
                }
                dataitem(NRCreditMemoReceived; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('NR'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessNRCreditMemoReceived;
                    end;
                }
                dataitem(FNNonResidentInvoices; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('FN'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessFNNonResidentInvoices;
                    end;
                }
                dataitem(SEServicePurchase; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Line No.") WHERE("Record Identifier" = CONST('SE'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessSEServicePurchase;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not DetailedExport then
                        CurrReport.Skip();
                end;
            }
            dataitem(AggregatedRecords; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                dataitem(FAInvoices; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "VAT Group Identifier") WHERE("Record Identifier" = FILTER('FE' | 'FR' | 'NE' | 'NR'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessFAInvoices;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if CurrentVATEntity."Entry No." <> 0 then
                            WriteFALine(CurrentVATEntity);
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreProcessFAInvoices;
                    end;
                }
                dataitem(BLTransactions; "VAT Report Line")
                {
                    DataItemLink = "VAT Report No." = FIELD("No.");
                    DataItemLinkReference = "VAT Report Header";
                    DataItemTableView = SORTING("VAT Report No.", "Record Identifier", "VAT Group Identifier") WHERE("Record Identifier" = FILTER('FN' | 'SE' | 'BL'), "Incl. in Report" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessBLTransactions;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if (CurrentBLRecordIdentifier <> '') and (CurrentVATEntity."Entry No." <> 0) then
                            WriteBLLine(CurrentVATEntity, CurrentBLRecordIdentifier);
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreProcessBLTransactions;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if DetailedExport then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ProcessVATReportHeader;
            end;

            trigger OnPostDataItem()
            begin
                Spesometro.EndFile;

                FileName := StrSubstNo(ZipFilenamesLbl,
                    Format("VAT Report Header"."Start Date", 0, '<Day,2><Month,2><Year>'),
                    Format("VAT Report Header"."End Date", 0, '<Day,2><Month,2><Year>'));

                Spesometro.FinalizeReport(FileName);
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
                    field(DetailedExport; DetailedExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Export';
                        ToolTip = 'Specifies the detailed export.';
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

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        CurrentVATEntity: Record "VAT Entry";
        Spesometro: Codeunit "Spesometro Export";
        FileName: Text[250];
        DetailedExport: Boolean;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        CurrentVATEntityIdentifier: Text;
        CurrentBLRecordIdentifier: Code[30];
        CurrentBillToPayTo: Code[20];
        FASumUp: array[12] of Decimal;
        FASumUpIndex: Option ,NoActiveOpr,NoPassOpr,BaseInvoiceActive,VATInvoiceActive,NonDeductActive,BaseCMActive,VATCMActive,BaseInvoicePassive,VATInvoicePassive,NonDeductPassive,BaseCMPassive,VATCMPassive;
        BLSumUp: array[4] of Decimal;
        BLSumUpIndex: Option ,ActiveBase,ActiveVAT,PassiveBase,PassiveVAT;
        UnsupportedEntryTypeErr: Label 'Unsupported VAT Entry type = %1.', Comment = '%1 = VAT entry type';
        IsVATEntityInitialized: Boolean;
        ConstModuleGroup: Option ,TA001001,TA002001,TA003001,TA003002,TA003003,TA004001,TA004002,TA005001,TA005002,TA006001,TA007001,TA008001,TA009001,TA010001,TA011001;
        ConstFrameworkGroup: Option ,FA,SA,BL,FE,FR,NE,NR,DF,FN,SE,TU;
        ZipFilenamesLbl: Label 'VATReport-%1-%2.ccf', Comment = 'VATReport-010116-311216.ccf';

    local procedure ProcessVATReportHeader()
    var
        OrgVATReportHeader: Record "VAT Report Header";
        PeriodType: Option Month,Quarter,Year,Hide;
    begin
        with Spesometro do begin
            Initialize(DetailedExport, "VAT Report Header"."Start Date", "VAT Report Header"."End Date", PeriodType::Hide);
            SetTotalNumberOfRecords(EstimateNumberOfRecords);

            if "VAT Report Header"."VAT Report Type" <> "VAT Report Header"."VAT Report Type"::Standard then begin
                OrgVATReportHeader.Get("VAT Report Header"."Original Report No.");
                SetReportTypeData(MapVATReportType("VAT Report Header"."VAT Report Type"),
                  OrgVATReportHeader."Tax Auth. Doc. No.", OrgVATReportHeader."Tax Auth. Receipt No.");
            end;

            // Set framework count
            if not DetailedExport then begin
                SetTotalFrameworkCount(ConstFrameworkGroup::FA, EstimateNumberOfFARecords); // FA
                SetTotalFrameworkCount(ConstFrameworkGroup::BL, EstimateNumberOfBLRecords); // BL
            end else begin
                FEInvoicesIssued.SetRange("VAT Report No.", "VAT Report Header"."No.");
                FEInvoicesIssued.SetRange("Incl. in Report", true);
                FRInvoicesReceived.SetRange("VAT Report No.", "VAT Report Header"."No.");
                FRInvoicesReceived.SetRange("Incl. in Report", true);
                NECreditMemoIssued.SetRange("VAT Report No.", "VAT Report Header"."No.");
                NECreditMemoIssued.SetRange("Incl. in Report", true);
                NRCreditMemoReceived.SetRange("VAT Report No.", "VAT Report Header"."No.");
                NRCreditMemoReceived.SetRange("Incl. in Report", true);
                FNNonResidentInvoices.SetRange("VAT Report No.", "VAT Report Header"."No.");
                FNNonResidentInvoices.SetRange("Incl. in Report", true);
                SEServicePurchase.SetRange("VAT Report No.", "VAT Report Header"."No.");
                SEServicePurchase.SetRange("Incl. in Report", true);

                SetTotalFrameworkCount(ConstFrameworkGroup::FE, FEInvoicesIssued.Count); // FE
                SetTotalFrameworkCount(ConstFrameworkGroup::FR, FRInvoicesReceived.Count); // FR
                SetTotalFrameworkCount(ConstFrameworkGroup::NE, NECreditMemoIssued.Count); // NE
                SetTotalFrameworkCount(ConstFrameworkGroup::NR, NRCreditMemoReceived.Count); // NR
                SetTotalFrameworkCount(ConstFrameworkGroup::FN, FNNonResidentInvoices.Count); // FN
                SetTotalFrameworkCount(ConstFrameworkGroup::SE, SEServicePurchase.Count); // SE
            end;

            StartNewFile;
        end;
    end;

    local procedure ProcessFEInvoicesIssued()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        SummaryDocument: Boolean;
    begin
        with FEInvoicesIssued do begin
            VATEntry.Get("VAT Entry No.");
            if Customer.Get(VATEntry."Bill-to/Pay-to No.") then;

            Spesometro.StartNewRecord(ConstRecordType::D);
            if GetCustomerVATRegNo(Customer, VATEntry) <> '' then
                WriteBlockValue('FE001001', ConstFormat::PI, GetCustomerVATRegNo(Customer, VATEntry))
            else
                if GetCustomerFiscalCode(Customer, VATEntry) <> '' then
                    WriteBlockValue('FE001002', ConstFormat::CF, GetCustomerFiscalCode(Customer, VATEntry))
                else
                    SummaryDocument := true;

            if SummaryDocument then begin
                WriteBlockValue('FE001003', ConstFormat::CB, '1');
                Spesometro.IncrementCount(ConstModuleGroup::TA004002);
            end else
                Spesometro.IncrementCount(ConstModuleGroup::TA004001);

            if IsSelfBilled(GetCustomerVATRegNo(Customer, VATEntry)) then
                WriteBlockValue('FE001006', ConstFormat::CB, '1');

            WriteBlockValue('FE001007', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('FE001008', ConstFormat::DT, FormatDate(VATEntry."Posting Date", ConstFormat::DT));
            WriteBlockValue('FE001009', ConstFormat::AN, "Document No.");
            WriteBlockValue('FE001010', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('FE001011', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));
            if CheckBase(Base) then
                WriteBlockValue('FE001012', ConstFormat::CB, '1')
            else
                WriteBlockValue('FE001012', ConstFormat::CB, '0');
        end;
    end;

    local procedure ProcessFRInvoicesReceived()
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        with FRInvoicesReceived do begin
            VATEntry.Get("VAT Entry No.");
            if Vendor.Get(VATEntry."Bill-to/Pay-to No.") then;

            Spesometro.StartNewRecord(ConstRecordType::D);
            if GetVendorVATRegNo(Vendor, VATEntry) <> '' then begin
                WriteBlockValue('FR001001', ConstFormat::PI, GetVendorVATRegNo(Vendor, VATEntry));
                Spesometro.IncrementCount(ConstModuleGroup::TA005001);
            end else begin
                WriteBlockValue('FR001002', ConstFormat::CB, '1');
                Spesometro.IncrementCount(ConstModuleGroup::TA005002);
            end;

            WriteBlockValue('FR001003', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('FR001004', ConstFormat::DT, FormatDate(VATEntry."Posting Date", ConstFormat::DT));

            if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then
                WriteBlockValue('FR001006', ConstFormat::CB, '1')
            else
                WriteBlockValue('FR001006', ConstFormat::CB, '0');

            if IsSelfBilled(GetVendorVATRegNo(Vendor, VATEntry)) then
                WriteBlockValue('FR001007', ConstFormat::CB, '1');

            WriteBlockValue('FR001008', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('FR001009', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));

            if CheckBase(Base) then
                WriteBlockValue('FR001010', ConstFormat::CB, '1')
            else
                WriteBlockValue('FR001010', ConstFormat::CB, '0');
        end;
    end;

    local procedure ProcessNECreditMemoIssued()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
    begin
        with NECreditMemoIssued do begin
            VATEntry.Get("VAT Entry No.");
            if Customer.Get(VATEntry."Bill-to/Pay-to No.") then;

            Spesometro.StartNewRecord(ConstRecordType::D);
            if GetCustomerVATRegNo(Customer, VATEntry) <> '' then
                WriteBlockValue('NE001001', ConstFormat::PI, GetCustomerVATRegNo(Customer, VATEntry))
            else
                WriteBlockValue('NE001002', ConstFormat::CF, GetCustomerFiscalCode(Customer, VATEntry));

            WriteBlockValue('NE001003', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('NE001004', ConstFormat::DT, FormatDate(VATEntry."Posting Date", ConstFormat::DT));
            WriteBlockValue('NE001005', ConstFormat::AN, "Document No.");
            WriteBlockValue('NE001006', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('NE001007', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));

            if CheckBase(Base) then
                WriteBlockValue('NE001008', ConstFormat::CB, '1')
            else
                WriteBlockValue('NE001008', ConstFormat::CB, '0');

            Spesometro.IncrementCount(ConstModuleGroup::TA006001);
        end;
    end;

    local procedure ProcessNRCreditMemoReceived()
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        with NRCreditMemoReceived do begin
            VATEntry.Get("VAT Entry No.");
            if Vendor.Get(VATEntry."Bill-to/Pay-to No.") then;

            Spesometro.StartNewRecord(ConstRecordType::D);
            WriteBlockValue('NR001001', ConstFormat::PI, GetVendorVATRegNo(Vendor, VATEntry));
            WriteBlockValue('NR001002', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('NR001003', ConstFormat::DT, FormatDate(VATEntry."Posting Date", ConstFormat::DT));

            WriteBlockValue('NR001004', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('NR001005', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));

            if CheckBase(Base) then
                WriteBlockValue('NR001006', ConstFormat::CB, '1')
            else
                WriteBlockValue('NR001006', ConstFormat::CB, '0');

            Spesometro.IncrementCount(ConstModuleGroup::TA007001);
        end;
    end;

    local procedure ProcessFNNonResidentInvoices()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        with FNNonResidentInvoices do begin
            VATEntry.Get("VAT Entry No.");
            if Customer.Get("Bill-to/Pay-to No.") then
                CountryRegion.Get(Customer."Country/Region Code");

            Spesometro.StartNewRecord(ConstRecordType::D);
            if VATEntry."Individual Person" then begin
                WriteBlockValue('FN001001', ConstFormat::AN, VATEntry."Last Name");
                WriteBlockValue('FN001002', ConstFormat::AN, VATEntry."First Name");
                WriteBlockValue('FN001003', ConstFormat::DT, FormatDate(VATEntry."Date of Birth", ConstFormat::DT));
                WriteBlockValue('FN001004', ConstFormat::AN, VATEntry."Place of Birth");
                WriteBlockValue('FN001005', ConstFormat::PN, Customer.County);
                WriteBlockValue('FN001006', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
            end else begin
                WriteBlockValue('FN001007', ConstFormat::AN, Customer.Name);
                WriteBlockValue('FN001008', ConstFormat::AN, Customer.City);
                WriteBlockValue('FN001009', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
                WriteBlockValue('FN001010', ConstFormat::AN, Customer.Address);
            end;

            WriteBlockValue('FN001011', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('FN001012', ConstFormat::DT, FormatDate("Posting Date", ConstFormat::DT));
            WriteBlockValue('FN001013', ConstFormat::AN, "Document No.");
            WriteBlockValue('FN001015', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('FN001016', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));
            if CheckBase(Base) then
                WriteBlockValue('FN001017', ConstFormat::CB, '1')
            else
                WriteBlockValue('FN001017', ConstFormat::CB, '0');

            Spesometro.IncrementCount(ConstModuleGroup::TA009001);
        end;
    end;

    local procedure ProcessSEServicePurchase()
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        with SEServicePurchase do begin
            VATEntry.Get("VAT Entry No.");
            if Vendor.Get("Bill-to/Pay-to No.") then
                CountryRegion.Get(Vendor."Country/Region Code");

            Spesometro.StartNewRecord(ConstRecordType::D);
            if VATEntry."Individual Person" then begin
                WriteBlockValue('SE001001', ConstFormat::AN, VATEntry."Last Name");
                WriteBlockValue('SE001002', ConstFormat::AN, VATEntry."First Name");
                WriteBlockValue('SE001003', ConstFormat::DT, FormatDate(VATEntry."Date of Birth", ConstFormat::DT));
                WriteBlockValue('SE001004', ConstFormat::AN, VATEntry."Place of Birth");
                WriteBlockValue('SE001005', ConstFormat::PN, Vendor.County);
                WriteBlockValue('SE001006', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
                WriteBlockValue('SE001011', ConstFormat::AN, GetVendorFiscalCode(Vendor, VATEntry));
            end else begin
                WriteBlockValue('SE001007', ConstFormat::AN, Vendor.Name);
                WriteBlockValue('SE001008', ConstFormat::AN, Vendor.City);
                WriteBlockValue('SE001009', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
                WriteBlockValue('SE001010', ConstFormat::AN, Vendor.Address);
            end;
            if CountryRegion."Foreign Country/Region Code" in ['37', '037', ' 37', '37 '] then
                WriteBlockValue('SE001011', ConstFormat::AN, GetVendorVATRegNo(Vendor, VATEntry));

            WriteBlockValue('SE001012', ConstFormat::DT, FormatDate(VATEntry."Document Date", ConstFormat::DT));
            WriteBlockValue('SE001013', ConstFormat::DT, FormatDate("Posting Date", ConstFormat::DT));
            WriteBlockValue('SE001014', ConstFormat::AN, "Document No.");
            WriteBlockValue('SE001015', ConstFormat::NP, FormatNum(Base, ConstFormat::NP));
            WriteBlockValue('SE001016', ConstFormat::NP, FormatNum(Amount, ConstFormat::NP));
            if CheckBase(Base) then
                WriteBlockValue('SE001017', ConstFormat::CB, '1')
            else
                WriteBlockValue('SE001017', ConstFormat::CB, '0');

            Spesometro.IncrementCount(ConstModuleGroup::TA010001);
        end;
    end;

    local procedure PreProcessFAInvoices()
    begin
        CurrentVATEntity.Reset();
        CurrentVATEntityIdentifier := '';
        IsVATEntityInitialized := false;
        Clear(FASumUp);
    end;

    local procedure ProcessFAInvoices()
    var
        VATEntry: Record "VAT Entry";
    begin
        with FAInvoices do begin
            if ("VAT Group Identifier" <> CurrentVATEntityIdentifier) and
               IsVATEntityInitialized
            then begin
                WriteFALine(CurrentVATEntity);
                CurrentVATEntity.Reset();
                Clear(FASumUp);
                CurrentVATEntityIdentifier := '';
            end;

            if CurrentVATEntityIdentifier = '' then begin
                CurrentVATEntity.Get("VAT Entry No.");
                CurrentVATEntityIdentifier := "VAT Group Identifier";
            end;
            IsVATEntityInitialized := true;

            VATEntry.Get("VAT Entry No.");
            case "Record Identifier" of
                'FE': // Invoice Active
                    begin
                        FASumUp[FASumUpIndex::NoActiveOpr] += 1;
                        FASumUp[FASumUpIndex::BaseInvoiceActive] += Base;
                        FASumUp[FASumUpIndex::VATInvoiceActive] += Amount;
                    end;
                'FR': // Invoice Passive
                    begin
                        FASumUp[FASumUpIndex::NoPassOpr] += 1;
                        FASumUp[FASumUpIndex::BaseInvoicePassive] += Base;
                        FASumUp[FASumUpIndex::VATInvoicePassive] += Amount;
                    end;
                'NE': // Credit Memo Passive
                    begin
                        FASumUp[FASumUpIndex::NoPassOpr] += 1;
                        FASumUp[FASumUpIndex::BaseCMPassive] += Base;
                        FASumUp[FASumUpIndex::VATCMPassive] += Amount;
                    end;
                'NR': // Credit Memo Active
                    begin
                        FASumUp[FASumUpIndex::NoActiveOpr] += 1;
                        FASumUp[FASumUpIndex::BaseCMActive] += Base;
                        FASumUp[FASumUpIndex::VATCMActive] += Amount;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PreProcessBLTransactions()
    begin
        CurrentVATEntity.Reset();
        CurrentVATEntityIdentifier := '';
        CurrentBLRecordIdentifier := '';
        CurrentBillToPayTo := '';
        Clear(BLSumUp);
    end;

    local procedure ProcessBLTransactions()
    begin
        with BLTransactions do begin
            if ((("VAT Group Identifier" <> CurrentVATEntityIdentifier) or
                 ("Record Identifier" <> CurrentBLRecordIdentifier)) and (CurrentVATEntityIdentifier <> '')) or
               CurrLineDiffNonResidentCust(BLTransactions, CurrentBillToPayTo)
            then begin
                WriteBLLine(CurrentVATEntity, CurrentBLRecordIdentifier);
                CurrentVATEntity.Reset();
                CurrentVATEntityIdentifier := '';
                CurrentBLRecordIdentifier := '';
                CurrentBillToPayTo := '';
                Clear(BLSumUp);
            end;

            if CurrentVATEntityIdentifier = '' then begin
                CurrentVATEntity.Get("VAT Entry No.");
                CurrentVATEntityIdentifier := "VAT Group Identifier";
                CurrentBLRecordIdentifier := "Record Identifier";
                CurrentBillToPayTo := "Bill-to/Pay-to No.";
            end;

            case "Record Identifier" of
                'FN': // Invoice Active (sales)
                    begin
                        BLSumUp[BLSumUpIndex::ActiveBase] += Base;
                        BLSumUp[BLSumUpIndex::ActiveVAT] += Amount;
                    end;
                // Note: Missing credit memos for non-resident as it is not specified by the file format
                'SE': // Purchase of services from non-residents
                    begin
                        BLSumUp[BLSumUpIndex::PassiveBase] += Base;
                        BLSumUp[BLSumUpIndex::PassiveVAT] += Amount;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text[250]; Detailed: Boolean)
    begin
        Spesometro.SetServerFileName(NewFileName);
        FileName := NewFileName;
        DetailedExport := Detailed;
    end;

    [Scope('OnPrem')]
    procedure GetNoFiles(): Integer
    begin
        exit(Spesometro.GetTotalTransmissions);
    end;

    local procedure WriteFALine(var VATEntry: Record "VAT Entry")
    begin
        Spesometro.StartNewRecord(ConstRecordType::C);

        if (VATEntry."VAT Registration No." = CurrentVATEntityIdentifier) and (CurrentVATEntityIdentifier <> '') then
            WriteBlockValue('FA001001', ConstFormat::PI, CurrentVATEntityIdentifier)
        else
            if CurrentVATEntityIdentifier <> '' then
                WriteBlockValue('FA001002', ConstFormat::CF, CurrentVATEntityIdentifier)
            else
                WriteBlockValue('FA001003', ConstFormat::CB, '1');

        WriteBlockValue('FA001004', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::NoActiveOpr], ConstFormat::NP));
        WriteBlockValue('FA001005', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::NoPassOpr], ConstFormat::NP));

        WriteBlockValue('FA001007', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::BaseInvoiceActive], ConstFormat::NP));
        WriteBlockValue('FA001008', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::VATInvoiceActive], ConstFormat::NP));
        WriteBlockValue('FA001009', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::NonDeductActive], ConstFormat::NP));
        WriteBlockValue('FA001010', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::BaseCMActive], ConstFormat::NP));
        WriteBlockValue('FA001011', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::VATCMActive], ConstFormat::NP));

        WriteBlockValue('FA001012', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::BaseInvoicePassive], ConstFormat::NP));
        WriteBlockValue('FA001013', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::VATInvoicePassive], ConstFormat::NP));
        WriteBlockValue('FA001014', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::NonDeductPassive], ConstFormat::NP));
        WriteBlockValue('FA001015', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::BaseCMPassive], ConstFormat::NP));
        WriteBlockValue('FA001016', ConstFormat::NP, FormatNum(FASumUp[FASumUpIndex::VATCMPassive], ConstFormat::NP));

        Spesometro.IncrementCount(ConstModuleGroup::TA001001);
    end;

    local procedure WriteBLLine(var VATEntry: Record "VAT Entry"; RecordIdent: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        County: Text;
    begin
        Spesometro.StartNewRecord(ConstRecordType::C);

        case VATEntry.Type of
            VATEntry.Type::Sale:
                begin
                    if Customer.Get(VATEntry."Bill-to/Pay-to No.") then
                        CountryRegion.Get(Customer."Country/Region Code");
                    County := Customer.County;
                end;
            VATEntry.Type::Purchase:
                begin
                    if Vendor.Get(VATEntry."Bill-to/Pay-to No.") then
                        CountryRegion.Get(Vendor."Country/Region Code");
                    County := Vendor.County;
                end;
            else
                Error(UnsupportedEntryTypeErr, VATEntry.Type);
        end;

        if VATEntry."Individual Person" then begin
            WriteBlockValue('BL001001', ConstFormat::AN, VATEntry."Last Name");
            WriteBlockValue('BL001002', ConstFormat::AN, VATEntry."First Name");
            WriteBlockValue('BL001003', ConstFormat::DT, FormatDate(VATEntry."Date of Birth", ConstFormat::DT));
            WriteBlockValue('BL001004', ConstFormat::AN, VATEntry."Place of Birth");
            WriteBlockValue('BL001005', ConstFormat::PN, County);
            WriteBlockValue('BL001006', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
            WriteBlockValue('BL002001', ConstFormat::CF, CurrentVATEntityIdentifier)
        end else begin
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    begin
                        WriteBlockValue('BL001007', ConstFormat::AN, Customer.Name);
                        WriteBlockValue('BL001008', ConstFormat::AN, Customer.City);
                        WriteBlockValue('BL001009', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
                        WriteBlockValue('BL001010', ConstFormat::AN, Customer.Address);
                    end;
                VATEntry.Type::Purchase:
                    begin
                        WriteBlockValue('BL001007', ConstFormat::AN, Vendor.Name);
                        WriteBlockValue('BL001008', ConstFormat::AN, Vendor.City);
                        WriteBlockValue('BL001009', ConstFormat::NU, CountryRegion."Foreign Country/Region Code");
                        WriteBlockValue('BL001010', ConstFormat::AN, Vendor.Address);
                    end;
            end;

            WriteBlockValue('BL002001', ConstFormat::PI, CurrentVATEntityIdentifier);
        end;

        if (RecordIdent = 'SE') and VATEntry."EU Service" then begin
            WriteBlockValue('BL002004', ConstFormat::CB, '1');
            Spesometro.IncrementCount(ConstModuleGroup::TA003003)
        end else begin
            WriteBlockValue('BL002003', ConstFormat::CB, '1');
            Spesometro.IncrementCount(ConstModuleGroup::TA003002);
        end;

        WriteBlockValue('BL003001', ConstFormat::NP, FormatNum(BLSumUp[BLSumUpIndex::ActiveBase], ConstFormat::NP));
        WriteBlockValue('BL003002', ConstFormat::NP, FormatNum(BLSumUp[BLSumUpIndex::ActiveVAT], ConstFormat::NP));

        WriteBlockValue('BL006001', ConstFormat::NP, FormatNum(BLSumUp[BLSumUpIndex::PassiveBase], ConstFormat::NP));
        WriteBlockValue('BL006002', ConstFormat::NP, FormatNum(BLSumUp[BLSumUpIndex::PassiveVAT], ConstFormat::NP));
    end;

    local procedure EstimateNumberOfRecords(): Integer
    var
        VATReportLine: Record "VAT Report Line";
    begin
        if DetailedExport then begin
            VATReportLine.SetRange("VAT Report No.", "VAT Report Header"."No.");
            VATReportLine.SetRange("Incl. in Report", true);
            exit(VATReportLine.Count);
        end;
        exit(EstimateNumberOfFARecords + EstimateNumberOfBLRecords);
    end;

    local procedure EstimateNumberOfFARecords(): Integer
    var
        VATReportLinePrev: Record "VAT Report Line";
        DistinctCount: Integer;
    begin
        FAInvoices.SetCurrentKey("VAT Report No.", "VAT Group Identifier");
        FAInvoices.SetRange("VAT Report No.", "VAT Report Header"."No.");
        FAInvoices.SetRange("Incl. in Report", true);
        FAInvoices.SetFilter("Record Identifier", 'FE|FR|NE|NR');
        VATReportLinePrev.Init();
        if FAInvoices.FindSet then begin
            repeat
                if (VATReportLinePrev."VAT Group Identifier" <> FAInvoices."VAT Group Identifier") or
                   (VATReportLinePrev."VAT Report No." <> FAInvoices."VAT Report No.")
                then // to pass first record(s) with empty VAT Group Id
                    DistinctCount := DistinctCount + 1;
                VATReportLinePrev := FAInvoices;
            until FAInvoices.Next = 0;
            if DistinctCount = 0 then
                DistinctCount += 1;
        end;
        FAInvoices.Reset();

        exit(DistinctCount);
    end;

    local procedure EstimateNumberOfBLRecords(): Integer
    var
        VATReportLinePrev: Record "VAT Report Line";
        DistinctCount: Integer;
    begin
        BLTransactions.SetCurrentKey("VAT Report No.", "Record Identifier", "VAT Group Identifier");
        BLTransactions.SetRange("VAT Report No.", "VAT Report Header"."No.");
        BLTransactions.SetRange("Incl. in Report", true);
        BLTransactions.SetFilter("Record Identifier", 'FN|SE|BL');
        VATReportLinePrev.Init();
        if BLTransactions.FindSet then
            repeat
                if ((VATReportLinePrev."Record Identifier" <> BLTransactions."Record Identifier") or
                    (VATReportLinePrev."VAT Group Identifier" <> BLTransactions."VAT Group Identifier")) or
                   ((BLTransactions.Type = BLTransactions.Type::Sale) and
                    (VATReportLinePrev."Bill-to/Pay-to No." <> BLTransactions."Bill-to/Pay-to No.") and
                    CustomerIsNonResident(BLTransactions."Bill-to/Pay-to No."))
                then
                    DistinctCount := DistinctCount + 1;
                VATReportLinePrev := BLTransactions;
            until BLTransactions.Next = 0;
        BLTransactions.Reset();

        exit(DistinctCount);
    end;

    local procedure GetCustomerFiscalCode(var Customer: Record Customer; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."Fiscal Code" <> '' then
            exit(VATEntry."Fiscal Code");
        if Customer."Fiscal Code" <> '' then
            exit(Customer."Fiscal Code");
    end;

    local procedure GetCustomerVATRegNo(var Customer: Record Customer; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."VAT Registration No." <> '' then
            exit(VATEntry."VAT Registration No.");
        if Customer."VAT Registration No." <> '' then
            exit(Customer."VAT Registration No.");
    end;

    local procedure GetVendorFiscalCode(var Vendor: Record Vendor; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."Fiscal Code" <> '' then
            exit(VATEntry."Fiscal Code");
        if Vendor."Fiscal Code" <> '' then
            exit(Vendor."Fiscal Code");
    end;

    local procedure GetVendorVATRegNo(var Vendor: Record Vendor; var VATEntry: Record "VAT Entry"): Text
    begin
        if VATEntry."VAT Registration No." <> '' then
            exit(VATEntry."VAT Registration No.");
        if Vendor."VAT Registration No." <> '' then
            exit(Vendor."VAT Registration No.");
    end;

    local procedure IsSelfBilled(VATRegNo: Text): Boolean
    begin
        exit((VATRegNo = CompanyInfo."VAT Registration No.") and (CompanyInfo."VAT Registration No." <> ''));
    end;

    local procedure CheckBase(Base: Decimal): Boolean
    begin
        exit(Abs(Base) > 999999);
    end;

    local procedure FormatDate(InputDate: Date; OutputFormat: Option): Text
    begin
        exit(Spesometro.FormatDate(InputDate, OutputFormat));
    end;

    [Scope('OnPrem')]
    procedure FormatNum(Number: Decimal; ValueFormat: Option): Text
    begin
        exit(Spesometro.FormatNum(Number, ValueFormat));
    end;

    local procedure WriteBlockValue("Code": Code[8]; ValueFormat: Option; Value: Text)
    begin
        Spesometro.WriteBlockValue(Code, ValueFormat, Value);
    end;

    local procedure CustomerIsNonResident(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer.Resident = Customer.Resident::"Non-Resident");
        exit(false);
    end;

    local procedure CurrLineDiffNonResidentCust(VATReportLine: Record "VAT Report Line"; CurrentBillToPayTo: Code[20]): Boolean
    begin
        if (VATReportLine.Type = VATReportLine.Type::Sale) and
           (VATReportLine."Bill-to/Pay-to No." <> CurrentBillToPayTo) and
           CustomerIsNonResident(CurrentBillToPayTo)
        then
            exit(true);
        exit(false);
    end;
}

