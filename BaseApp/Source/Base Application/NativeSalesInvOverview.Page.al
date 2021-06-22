page 2811 "Native - Sales Inv. Overview"
{
    Caption = 'nativeInvoicingSalesInvoicesOverview', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = Id;
    PageType = List;
    SourceTable = "Sales Invoice Entity Aggregate";

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
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                    Editable = false;
                }
                field(customerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNumber', Locked = true;
                }
                field(customerName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'customerName', Locked = true;
                    Editable = false;
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the currency code.';
                }
                field(subtotalAmount; "Subtotal Amount")
                {
                    ApplicationArea = All;
                    Caption = 'subtotalAmount', Locked = true;
                    Editable = false;
                }
                field(totalAmountExcludingTax; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountExcludingTax', Locked = true;
                }
                field(totalTaxAmount; "Total Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'totalTaxAmount', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount for the sales invoice.';
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the status of the Sales Invoice (cancelled, paid, on hold, created).';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(isTest; IsTest)
                {
                    ApplicationArea = All;
                    Caption = 'isTest', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies if the sales invoice is a test invoice.';
                }
                field(lastEmailSentStatus; LastEmailSentStatus)
                {
                    ApplicationArea = All;
                    Caption = 'lastEmailSentStatus', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the status of the last sent email: Not Sent, In Process, Finished, or Error.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        if not GetParentRecordNativeInvoicing(SalesHeader, SalesInvoiceHeader) then begin
            GraphMgtGeneralTools.CleanAggregateWithoutParent(Rec);
            exit;
        end;

        SetCalculatedFields;
        SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
        SelectLatestVersion;
    end;

    var
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        CurrencyCodeTxt: Text;
        LCYCurrencyCode: Code[10];
        LastEmailSentStatus: Option "Not Sent","In Process",Finished,Error;

    local procedure SetCalculatedFields()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
        GetParentRecordNativeInvoicing(SalesHeader, SalesInvoiceHeader);
        SetLastEmailSentStatus(SalesHeader, SalesInvoiceHeader);
    end;

    local procedure SetLastEmailSentStatus(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if Posted then
            LastEmailSentStatus := SalesInvoiceHeader."Last Email Sent Status"
        else
            LastEmailSentStatus := SalesHeader."Last Email Sent Status";
    end;
}

