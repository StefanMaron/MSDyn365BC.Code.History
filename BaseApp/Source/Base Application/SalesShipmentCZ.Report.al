#if not CLEAN17
report 31098 "Sales - Shipment CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesShipmentCZ.rdlc';
    Caption = 'Sales - Shipment CZ (Obsolete)';
    PreviewMode = PrintLayout;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            DataItemTableView = SORTING("Primary Key");
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(RegistrationNo_CompanyInformation; "Registration No.")
            {
            }
            column(VATRegistrationNo_CompanyInformation; "VAT Registration No.")
            {
            }
            column(HomePage_CompanyInformation; "Home Page")
            {
            }
            column(Picture_CompanyInformation; Picture)
            {
            }
            dataitem("Sales & Receivables Setup"; "Sales & Receivables Setup")
            {
                DataItemTableView = SORTING("Primary Key");
                column(LogoPositiononDocuments_SalesReceivablesSetup; Format("Logo Position on Documents", 0, 2))
                {
                }
                dataitem("General Ledger Setup"; "General Ledger Setup")
                {
                    DataItemTableView = SORTING("Primary Key");
                    column(LCYCode_GeneralLedgerSetup; "LCY Code")
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Company(CompanyAddr, "Company Information");
            end;
        }
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
            column(DocumentLbl; DocumentLbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(CopyLbl; CopyLbl)
            {
            }
            column(VendorLbl; VendLbl)
            {
            }
            column(CustomerLbl; CustLbl)
            {
            }
            column(ShipToLbl; ShipToLbl)
            {
            }
            column(PaymentTermsLbl; PaymentTermsLbl)
            {
            }
            column(PaymentMethodLbl; PaymentMethodLbl)
            {
            }
            column(ShipmentMethodLbl; ShipmentMethodLbl)
            {
            }
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(UoMLbl; UoMLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(SubtotalLbl; SubtotalLbl)
            {
            }
            column(DiscPercentLbl; DiscPercentLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(VATLbl; VATLbl)
            {
            }
            column(No_SalesShipmentHeader; "No.")
            {
            }
            column(VATRegistrationNo_SalesShipmentHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_SalesShipmentHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_SalesShipmentHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_SalesShipmentHeader; "Registration No.")
            {
            }
            column(BankAccountNo_SalesShipmentHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_SalesShipmentHeader; "Bank Account No.")
            {
            }
            column(IBAN_SalesShipmentHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_SalesShipmentHeader; IBAN)
            {
            }
            column(BIC_SalesShipmentHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_SalesShipmentHeader; "SWIFT Code")
            {
            }
            column(DocumentDate_SalesShipmentHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_SalesShipmentHeader; "Document Date")
            {
            }
            column(ShipmentDate_SalesShipmentHeaderCaption; FieldCaption("Shipment Date"))
            {
            }
            column(ShipmentDate_SalesShipmentHeader; "Shipment Date")
            {
            }
            column(OrderNo_SalesShipmentHeaderCaption; FieldCaption("Order No."))
            {
            }
            column(OrderNo_SalesShipmentHeader; "Order No.")
            {
            }
            column(YourReference_SalesShipmentHeaderCaption; FieldCaption("Your Reference"))
            {
            }
            column(YourReference_SalesShipmentHeader; "Your Reference")
            {
            }
            column(ShipmentMethod; ShipmentMethod.Description)
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(CustAddr1; CustAddr[1])
            {
            }
            column(CustAddr2; CustAddr[2])
            {
            }
            column(CustAddr3; CustAddr[3])
            {
            }
            column(CustAddr4; CustAddr[4])
            {
            }
            column(CustAddr5; CustAddr[5])
            {
            }
            column(CustAddr6; CustAddr[6])
            {
            }
            column(ShipToAddr1; ShipToAddr[1])
            {
            }
            column(ShipToAddr2; ShipToAddr[2])
            {
            }
            column(ShipToAddr3; ShipToAddr[3])
            {
            }
            column(ShipToAddr4; ShipToAddr[4])
            {
            }
            column(ShipToAddr5; ShipToAddr[5])
            {
            }
            column(ShipToAddr6; ShipToAddr[6])
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; Number)
                {
                }
                dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = FIELD("Salesperson Code");
                    DataItemLinkReference = "Sales Shipment Header";
                    DataItemTableView = SORTING(Code);
                    column(Name_SalespersonPurchaser; Name)
                    {
                    }
                    column(EMail_SalespersonPurchaser; "E-Mail")
                    {
                    }
                    column(PhoneNo_SalespersonPurchaser; "Phone No.")
                    {
                    }
                }
                dataitem("Sales Shipment Line"; "Sales Shipment Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemLinkReference = "Sales Shipment Header";
                    DataItemTableView = SORTING("Document No.", "Line No.");
                    column(LineNo_SalesShipmentLine; "Line No.")
                    {
                    }
                    column(Type_SalesShipmentLine; Format(Type, 0, 2))
                    {
                    }
                    column(No_SalesShipmentLineCaption; FieldCaption("No."))
                    {
                    }
                    column(No_SalesShipmentLine; "No.")
                    {
                    }
                    column(Description_SalesShipmentLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_SalesShipmentLine; Description)
                    {
                    }
                    column(Quantity_SalesShipmentLineCaption; FieldCaption(Quantity))
                    {
                    }
                    column(Quantity_SalesShipmentLine; Quantity)
                    {
                    }
                    column(UnitofMeasure_SalesShipmentLine; "Unit of Measure")
                    {
                    }
                    dataitem(ItemTrackingLine; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(LotNo_TrackingSpecBuffer; TrackingSpecBuf."Lot No.")
                        {
                        }
                        column(SerNo_TrackingSpecBuffer; TrackingSpecBuf."Serial No.")
                        {
                        }
                        column(Expiration_TrackingSpecBuffer; TrackingSpecBuf."Expiration Date")
                        {
                        }
                        column(Quantity_TrackingSpecBuffer; TrackingSpecBuf."Quantity (Base)")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TrackingSpecBuf.FindSet
                            else
                                TrackingSpecBuf.Next;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TrackingSpecBuf.SetRange("Source Ref. No.", "Sales Shipment Line"."Line No.");

                            TrackingSpecCount := TrackingSpecBuf.Count();
                            if TrackingSpecCount = 0 then
                                CurrReport.Break();

                            SetRange(Number, 1, TrackingSpecCount);
                            TrackingSpecBuf.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
                              "Source Prod. Order Line", "Source Ref. No.");
                        end;
                    }
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Sales Shipment Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
                        DataItemLink = "No." = FIELD("Employee No.");
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; FullName)
                        {
                        }
                        column(PhoneNo_Employee; "Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; "Company E-Mail")
                        {
                        }
                    }
                }

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales Shpt.-Printed", "Sales Shipment Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                DocFooter.SetFilter("Language Code", '%1|%2', '', "Language Code");
                if DocFooter.FindLast then
                    DocFooterText := DocFooter."Footer Text"
                else
                    DocFooterText := '';

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                FormatAddr.SalesShptShipTo(ShipToAddr, "Sales Shipment Header");
                FormatAddr.SalesShptBillTo(CustAddr, ShipToAddr, "Sales Shipment Header");

                if "Shipment Method Code" = '' then
                    ShipmentMethod.Init
                else begin
                    ShipmentMethod.Get("Shipment Method Code");
                    ShipmentMethod.TranslateDescription(ShipmentMethod, "Language Code");
                end;

                if LogInteraction and not IsReportInPreviewMode then
                    SegMgt.LogDocument(
                      5, "No.", 0, 0, DATABASE::Customer, "Sell-to Customer No.", "Salesperson Code",
                      "Campaign No.", "Posting Description", '');

                if ShowLotSN then begin
                    ItemTrackingDocMgt.SetRetrieveAsmItemTracking(true);
                    TrackingSpecCount :=
                      ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuf,
                        "No.", DATABASE::"Sales Shipment Header", 0);
                    ItemTrackingDocMgt.SetRetrieveAsmItemTracking(false);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies to print.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to record the sales shipment you print as Interactions and add them to the Interaction Log Entry table.';
                    }
                    field(ShowLotSN; ShowLotSN)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Serial/Lot Number Appendix';
                        ToolTip = 'Specifies when the show serial/lot number appendixis to be show';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        ShipmentMethod: Record "Shipment Method";
        DocFooter: Record "Document Footer";
        TrackingSpecBuf: Record "Tracking Specification" temporary;
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        SegMgt: Codeunit SegManagement;
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        LogInteraction: Boolean;
        [InDataSet]
        LogInteractionEnable: Boolean;
        ShowLotSN: Boolean;
        TrackingSpecCount: Integer;
        DocumentLbl: Label 'Shipment';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        ShipToLbl: Label 'Ship-to';
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        ShipmentMethodLbl: Label 'Shipment Method';
        SalespersonLbl: Label 'Salesperson';
        UoMLbl: Label 'UoM';
        CreatorLbl: Label 'Posted by';
        SubtotalLbl: Label 'Subtotal';
        DiscPercentLbl: Label 'Discount %';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegMgt.FindInteractTmplCode(5) <> '';
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}
#endif