report 18048 "e-Invoice"
{
    Caption = 'e-Invoice';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(content)
            {
                field("Document Type"; DocType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the posted document type for which report will run.';

                    trigger OnValidate()
                    begin
                        if DocType in [DocType::"Blanket Order", DocType::Order, DocType::Quote, DocType::"Return Order"] then
                            Error(DocTypeErr);
                    end;
                }
                field("Document No"; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the posted document type for which report will run.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        case DocType of
                            DocType::Invoice:
                                if Page.RunModal(Page::"Posted Sales Invoices", SalesInvoiceHeaderDummy) = ACTION::LookupOK then
                                    DocNo := SalesInvoiceHeaderDummy."No.";
                            DocType::"Credit Memo":
                                if Page.RunModal(Page::"Posted Sales Credit Memos", SalesCrMemoHeaderDummy) = ACTION::LookupOK then
                                    DocNo := SalesCrMemoHeaderDummy."No.";
                        end;

                    end;

                    trigger OnValidate()
                    begin
                        if DocNo <> '' then
                            case DocType of
                                DocType::Invoice:
                                    SalesInvoiceHeaderDummy.GET(DocNo);
                                DocType::"Credit Memo":
                                    SalesCrMemoHeaderDummy.GET(DocNo);
                            end;
                    end;
                }
            }
        }
    }


    trigger OnInitReport()
    begin
        InitilizaRequestPage();
    end;

    trigger OnPostReport()
    begin
        if DocType = DocType::Invoice then begin
            eInvoice.SetSalesInvHeader(SalesInvoiceHeaderDummy);
            eInvoice.Run();
        end else begin
            eInvoice.SetCrMemoHeader(SalesCrMemoHeaderDummy);
            eInvoice.Run();
        end;
    end;

    var
        SalesInvoiceHeaderDummy: Record "Sales Invoice Header";
        SalesCrMemoHeaderDummy: Record "Sales Cr.Memo Header";
        eInvoice: Codeunit "e-Invoice";
        DocType: Enum "Sales Document Type";
        DocNo: Code[20];
        DocTypeErr: Label 'Document Type must be equal to Invoice or Credit Memo';

    local procedure InitilizaRequestPage()
    begin
        DocType := DocType::Invoice;
    end;
}