report 1094 "Job Transfer to Sales Invoice"
{
    Caption = 'Job Transfer to Sales Invoice';
    ProcessingOnly = true;

    dataset
    {
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
                    field(CreateNewInvoice; NewInvoice)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create New Invoice';
                        ToolTip = 'Specifies if the batch job creates a new sales invoice.';

                        trigger OnValidate()
                        begin
                            if NewInvoice then begin
                                InvoiceNo := '';
                                if PostingDate = 0D then
                                    PostingDate := WorkDate;
                                InvoicePostingDate := 0D;
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
                        end;
                    }
                    field(AppendToSalesInvoiceNo; InvoiceNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Append to Sales Invoice No.';
                        ToolTip = 'Specifies the number of the sales invoice that you want to append the lines to if you did not select the Create New Sales Invoice field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(SalesHeader);
                            SalesHeader.FilterGroup := 2;
                            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                            SalesHeader.SetRange("Bill-to Customer No.", Job."Bill-to Customer No.");
                            SalesHeader.FilterGroup := 0;
                            if PAGE.RunModal(0, SalesHeader) = ACTION::LookupOK then
                                InvoiceNo := SalesHeader."No.";
                            if InvoiceNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
                                InvoicePostingDate := SalesHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport;
                        end;

                        trigger OnValidate()
                        begin
                            if InvoiceNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
                                InvoicePostingDate := SalesHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport;
                        end;
                    }
                    field(InvoicePostingDate; InvoicePostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Invoice Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies, if you filled in the Append to Sales Invoice No. field, the posting date of the invoice.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitReport;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Done := false;
    end;

    trigger OnPostReport()
    begin
        Done := true;
    end;

    var
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        NewInvoice: Boolean;
        InvoiceNo: Code[20];
        PostingDate: Date;
        InvoicePostingDate: Date;
        Done: Boolean;

    procedure GetInvoiceNo(var Done2: Boolean; var NewInvoice2: Boolean; var PostingDate2: Date; var InvoiceNo2: Code[20])
    begin
        Done2 := Done;
        NewInvoice2 := NewInvoice;
        PostingDate2 := PostingDate;
        InvoiceNo2 := InvoiceNo;
    end;

    procedure InitReport()
    begin
        PostingDate := WorkDate;
        NewInvoice := true;
        InvoiceNo := '';
        InvoicePostingDate := 0D;
    end;

    procedure SetCustomer(JobNo: Code[20])
    begin
        Job.Get(JobNo);
    end;
}

