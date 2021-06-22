table 2103 "O365 Sales Document"
{
    Caption = 'O365 Sales Document';
    ReplicateData = false;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Estimate,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(166; "Last Email Sent Time"; DateTime)
        {
            CalcFormula = Max ("O365 Document Sent History"."Created Date-Time" WHERE("Document Type" = FIELD("Document Type"),
                                                                                      "Document No." = FIELD("No."),
                                                                                      Posted = FIELD(Posted)));
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
        }
        field(167; "Last Email Sent Status"; Option)
        {
            CalcFormula = Lookup ("O365 Document Sent History"."Job Last Status" WHERE("Document Type" = FIELD("Document Type"),
                                                                                       "Document No." = FIELD("No."),
                                                                                       Posted = FIELD(Posted),
                                                                                       "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Sent Status';
            FieldClass = FlowField;
            OptionCaption = 'Not Sent,In Process,Finished,Error';
            OptionMembers = "Not Sent","In Process",Finished,Error;
        }
        field(168; "Sent as Email"; Boolean)
        {
            CalcFormula = Exist ("O365 Document Sent History" WHERE("Document Type" = FIELD("Document Type"),
                                                                    "Document No." = FIELD("No."),
                                                                    Posted = FIELD(Posted),
                                                                    "Job Last Status" = CONST(Finished)));
            Caption = 'Sent as Email';
            FieldClass = FlowField;
        }
        field(169; "Last Email Notif Cleared"; Boolean)
        {
            CalcFormula = Lookup ("O365 Document Sent History".NotificationCleared WHERE("Document Type" = FIELD("Document Type"),
                                                                                         "Document No." = FIELD("No."),
                                                                                         Posted = FIELD(Posted),
                                                                                         "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Notif Cleared';
            FieldClass = FlowField;
        }
        field(170; IsTest; Boolean)
        {
            Caption = 'IsTest';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2100; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(2101; Canceled; Boolean)
        {
            CalcFormula = Exist ("Cancelled Document" WHERE("Source ID" = CONST(112),
                                                            "Cancelled Doc. No." = FIELD("No.")));
            Caption = 'Canceled';
            FieldClass = FlowField;
        }
        field(2102; "Currency Symbol"; Text[10])
        {
            Caption = 'Currency Symbol';
        }
        field(2103; "Document Status"; Option)
        {
            Caption = 'Document Status';
            OptionCaption = 'Quote,Draft Invoice,Unpaid Invoice,Canceled Invoice,Paid Invoice,Overdue Invoice';
            OptionMembers = Quote,"Draft Invoice","Unpaid Invoice","Canceled Invoice","Paid Invoice","Overdue Invoice";
        }
        field(2104; "Sales Amount"; Decimal)
        {
            Caption = 'Sales Amount';
        }
        field(2105; "Outstanding Amount"; Decimal)
        {
            Caption = 'Outstanding Amount';
        }
        field(2106; "Total Invoiced Amount"; Text[250])
        {
            Caption = 'Total Invoiced Amount';
        }
        field(2107; "Outstanding Status"; Text[250])
        {
            Caption = 'Outstanding Status';
        }
        field(2108; "Document Icon"; MediaSet)
        {
            Caption = 'Document Icon';
            ObsoleteReason = 'We no longer show a document icon.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(2109; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            TableRelation = "Payment Method" WHERE("Use for Invoicing" = CONST(true));
        }
        field(2110; "Display No."; Text[20])
        {
            Caption = 'Display No.';
        }
        field(2111; "Quote Valid Until Date"; Date)
        {
            CalcFormula = Lookup ("Sales Header"."Quote Valid Until Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                                "No." = FIELD("No.")));
            Caption = 'Quote Valid Until Date';
            FieldClass = FlowField;
        }
        field(2112; "Quote Accepted"; Boolean)
        {
            CalcFormula = Lookup ("Sales Header"."Quote Accepted" WHERE("Document Type" = FIELD("Document Type"),
                                                                        "No." = FIELD("No.")));
            Caption = 'Quote Accepted';
            FieldClass = FlowField;
        }
        field(2113; "Quote Sent to Customer"; DateTime)
        {
            CalcFormula = Lookup ("Sales Header"."Quote Sent to Customer" WHERE("Document Type" = FIELD("Document Type"),
                                                                                "No." = FIELD("No.")));
            Caption = 'Quote Sent to Customer';
            FieldClass = FlowField;
        }
        field(2114; "Quote Accepted Date"; Date)
        {
            CalcFormula = Lookup ("Sales Header"."Quote Accepted Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                             "No." = FIELD("No.")));
            Caption = 'Quote Accepted Date';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", Posted)
        {
            Clustered = true;
        }
        key(Key2; "Sell-to Customer Name")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Document Date", "Sell-to Customer Name", "Total Invoiced Amount", "No.", "Outstanding Status", "Document Type")
        {
        }
    }

    var
        OverdueTxt: Label 'Overdue';
        AmountTxt: Label '%1%2', Comment = '%1=Currency symbol %2= amount';
        FormatTxt: Label '<Precision,2:2><Standard Format,0>', Locked = true;
        PaidTxt: Label 'Paid';
        CanceledTxt: Label 'Canceled';
        SortByDueDate: Boolean;
        DraftTxt: Label 'Draft';
        DisplayNoLbl: Label 'No. %1', Comment = '%1 = The posted invoice number';
        SentTxt: Label 'Sent %1', Comment = '%1 = date';
        AcceptedTxt: Label 'Accepted %1', Comment = '%1 = date';
        ExpiredTxt: Label 'Expired';
        InvoiceSentTxt: Label 'Sent';
        HideInvoices: Boolean;
        TestTxt: Label 'Test';
        InvoiceFailedTxt: Label 'Failed to send';

    procedure UpdateFields()
    var
        Currency: Record Currency;
    begin
        "Currency Symbol" := Currency.ResolveGLCurrencySymbol("Currency Code");

        if Posted then
            GetAmountsPosted
        else
            GetAmountsUnposted;

        if "Document Type" = "Document Type"::Quote then
            CalcFields("Quote Accepted", "Quote Valid Until Date", "Quote Sent to Customer", "Quote Accepted Date");

        AssignDocumentStatus;
        SetBrickStatus;
        SetDisplayNo;
    end;

    local procedure AssignDocumentStatus()
    begin
        case "Document Type" of
            "Document Type"::Quote:
                begin
                    case true of
                        "Quote Accepted":
                            "Document Status" := "Document Status"::"Paid Invoice";
                        QuoteIsExpired:
                            "Document Status" := "Document Status"::"Canceled Invoice";
                        "Quote Sent to Customer" <> 0DT:
                            "Document Status" := "Document Status"::"Unpaid Invoice";
                        else
                            "Document Status" := "Document Status"::"Draft Invoice";
                    end;
                    exit;
                end;
            "Document Type"::Invoice:
                CalcFields(Canceled);
            else
                exit;
        end;

        if not Posted then begin
            "Document Status" := "Document Status"::"Draft Invoice";
            exit;
        end;

        if Canceled then begin
            "Document Status" := "Document Status"::"Canceled Invoice";
            exit;
        end;

        if "Outstanding Amount" <= 0 then begin
            "Document Status" := "Document Status"::"Paid Invoice";
            exit;
        end;

        if IsOverduePostedInvoice then begin
            "Document Status" := "Document Status"::"Overdue Invoice";
            exit;
        end;

        "Document Status" := "Document Status"::"Unpaid Invoice";
    end;

    procedure IsOverduePostedInvoice(): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", "Sell-to Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", "No.");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Due Date", '<%1', WorkDate);
        exit(not CustLedgerEntry.IsEmpty);
    end;

    local procedure GetAmountsUnposted()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Document Type", "No.");
        SalesHeader.CalcFields("Amount Including VAT");
        "Sales Amount" := SalesHeader."Amount Including VAT";
        "Payment Method" := SalesHeader."Payment Method Code";
        "Outstanding Amount" := 0;
    end;

    local procedure GetAmountsPosted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get("No.");
        SalesInvoiceHeader.CalcFields("Amount Including VAT", "Remaining Amount");
        "Sales Amount" := SalesInvoiceHeader."Amount Including VAT";
        "Outstanding Amount" := SalesInvoiceHeader."Remaining Amount";
        "Payment Method" := SalesInvoiceHeader."Payment Method Code";
    end;

    local procedure SetBrickStatus()
    begin
        CalcFields("Last Email Sent Time", "Last Email Sent Status");

        if "Document Type" = "Document Type"::Quote then begin
            SetQuoteBrickStatus;
            exit;
        end;

        if not Posted then begin
            SetDraftInvoiceBrickStatus;
            exit;
        end;

        SetPostedDocumentBrickStatus;
    end;

    local procedure SetQuoteBrickStatus()
    var
        DummyZeroDateTime: DateTime;
    begin
        "Total Invoiced Amount" := StrSubstNo(AmountTxt, "Currency Symbol", Format("Sales Amount", 0, FormatTxt));

        CalcFields("Last Email Sent Time", "Last Email Sent Status");
        case true of
            "Quote Accepted":
                "Outstanding Status" := StrSubstNo(AcceptedTxt, "Quote Accepted Date");
            QuoteIsExpired:
                "Outstanding Status" := ExpiredTxt;
            "Last Email Sent Status" = "Last Email Sent Status"::Error:
                "Outstanding Status" := InvoiceFailedTxt;
            "Quote Sent to Customer" <> DummyZeroDateTime:
                "Outstanding Status" := StrSubstNo(SentTxt, DT2Date("Quote Sent to Customer"));
            else
                "Outstanding Status" := DraftTxt;
        end;
    end;

    local procedure SetPostedDocumentBrickStatus()
    begin
        "Total Invoiced Amount" := StrSubstNo(AmountTxt, "Currency Symbol", Format("Sales Amount", 0, FormatTxt));
        if "Outstanding Amount" <= 0 then begin
            CalcFields(Canceled);
            if Canceled then
                "Outstanding Status" := CanceledTxt
            else
                "Outstanding Status" := PaidTxt;
            exit;
        end;

        CalcFields("Last Email Sent Time", "Last Email Sent Status");
        case true of
            "Last Email Sent Status" = "Last Email Sent Status"::Error:
                "Outstanding Status" := InvoiceFailedTxt;
            IsOverduePostedInvoice:
                "Outstanding Status" := OverdueTxt;
            else
                "Outstanding Status" := InvoiceSentTxt;
        end;
    end;

    local procedure SetDraftInvoiceBrickStatus()
    begin
        "Total Invoiced Amount" := StrSubstNo(AmountTxt, "Currency Symbol", Format("Sales Amount", 0, FormatTxt));

        if IsTest then
            "Outstanding Status" := TestTxt
        else
            "Outstanding Status" := DraftTxt;
    end;

    local procedure SetDisplayNo()
    var
        CandidateDisplayNo: Text;
    begin
        if Posted then begin
            CandidateDisplayNo := StrSubstNo(DisplayNoLbl, "No.");
            if StrLen(CandidateDisplayNo) <= MaxStrLen("Display No.") then
                "Display No." := CopyStr(CandidateDisplayNo, 1, MaxStrLen("Display No."))
            else
                "Display No." := "No.";
        end else
            case "Document Type" of
                "Document Type"::Invoice:
                    "Display No." := DraftTxt;
                "Document Type"::Quote:
                    "Display No." := "No.";
                else
                    "Display No." := '';
            end;
    end;

    procedure OnFind(Which: Text): Boolean
    var
        FilterPosted: Boolean;
    begin
        case Which of
            '+':
                Posted := true; // Get last posted invoice
            '-':
                Posted := false; // Get first sales header
            else
                if HasPostedFilter(FilterPosted) then
                    Posted := Posted or FilterPosted;
        end;

        if Posted then
            exit(FindPostedDocument(Which));

        exit(FindUnpostedDocument(Which));
    end;

    procedure OnNext(Steps: Integer): Integer
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderResults: Integer;
        SalesInvoiceHeaderResults: Integer;
        StepOffset: Integer;
        FilterPosted: Boolean;
    begin
        if not HideInvoices then
            SetSalesInvoiceHeaderFilters(SalesInvoiceHeader);

        if not Posted then begin // Look for more Sales Headers
            SalesHeaderResults := GetNextUnpostedDocument(Steps);
            if SalesHeaderResults <> 0 then
                exit(SalesHeaderResults);

            if Steps < 0 then // No more sales headers and we are moving "back"
                exit(SalesHeaderResults); // therefore, no more recs, so this means we are done

            // No more sales headers, but we are moving forward so move on to sales invoice headers below
            if not SalesInvoiceHeader.FindSet then
                exit(0);

            StepOffset += 1; // need to adjust for one step that we did with FINDSET
        end else
            SalesInvoiceHeader.TransferFields(Rec); // Continue from current posted doc

        if HasPostedFilter(FilterPosted) and (not FilterPosted) then
            exit(GetPreviousUnpostedDocument(Steps));

        if not HideInvoices then begin
            SalesInvoiceHeaderResults := SalesInvoiceHeader.Next(Steps - StepOffset);
            if (SalesInvoiceHeaderResults + StepOffset) <> 0 then begin
                SetSalesInvoiceHeaderAsRec(SalesInvoiceHeader);
                exit(SalesInvoiceHeaderResults + StepOffset);
            end;
        end;

        exit(GetPreviousUnpostedDocument(Steps));
    end;

    local procedure SetSalesHeaderFilters(var SalesHeader: Record "Sales Header")
    begin
        SetSalesHeaderKey(SalesHeader);

        CopySalesHeaderFilters(SalesHeader);

        FilterGroup(-1);
        if GetFilter("Sell-to Customer Name") <> '' then begin
            SalesHeader.FilterGroup(-1);
            CopySalesHeaderFilters(SalesHeader);
            SalesHeader.FilterGroup(0);
        end;
        FilterGroup(0);

        SalesHeader.TransferFields(Rec);
    end;

    local procedure SetSalesInvoiceHeaderFilters(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SetSalesInvoiceHeaderKey(SalesInvoiceHeader);

        CopySalesInvoiceHeaderFilters(SalesInvoiceHeader);

        FilterGroup(-1);
        if GetFilter("Sell-to Customer Name") <> '' then begin
            SalesInvoiceHeader.FilterGroup(-1);
            CopySalesInvoiceHeaderFilters(SalesInvoiceHeader);
            SalesInvoiceHeader.FilterGroup(0);
        end;
        FilterGroup(0);

        SalesInvoiceHeader.TransferFields(Rec);
    end;

    local procedure CopySalesHeaderFilters(var SalesHeader: Record "Sales Header")
    begin
        CopyFilter("Document Type", SalesHeader."Document Type");
        CopyFilter("No.", SalesHeader."No.");
        CopyFilter("Sell-to Customer Name", SalesHeader."Sell-to Customer Name");
        CopyFilter("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        CopyFilter("Sell-to Contact", SalesHeader."Sell-to Contact");
        CopyFilter("Document Date", SalesHeader."Document Date");
        CopyFilter("Last Email Sent Status", SalesHeader."Last Email Sent Status");
        CopyFilter("Last Email Notif Cleared", SalesHeader."Last Email Notif Cleared");
        CopyFilter("Quote Sent to Customer", SalesHeader."Quote Sent to Customer");
        CopyFilter("Quote Accepted", SalesHeader."Quote Accepted");
        CopyFilter(IsTest, SalesHeader.IsTest);
    end;

    local procedure CopySalesInvoiceHeaderFilters(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CopyFilter("No.", SalesInvoiceHeader."No.");
        CopyFilter("Outstanding Amount", SalesInvoiceHeader."Remaining Amount");
        CopyFilter("Sell-to Customer Name", SalesInvoiceHeader."Sell-to Customer Name");
        CopyFilter("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        CopyFilter("Sell-to Contact", SalesInvoiceHeader."Sell-to Contact");
        CopyFilter("Document Date", SalesInvoiceHeader."Document Date");
        CopyFilter("Last Email Sent Status", SalesInvoiceHeader."Last Email Sent Status");
        CopyFilter("Last Email Notif Cleared", SalesInvoiceHeader."Last Email Notif Cleared");
        CopyFilter(Canceled, SalesInvoiceHeader.Cancelled);
    end;

    local procedure SetSalesHeaderAsRec(var SalesHeader: Record "Sales Header")
    begin
        TransferFields(SalesHeader);
        Posted := false;
        UpdateFields;
    end;

    local procedure SetSalesInvoiceHeaderAsRec(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        TransferFields(SalesInvoiceHeader);
        Posted := true;
        "Document Type" := "Document Type"::Invoice;
        UpdateFields;
    end;

    local procedure FindUnpostedDocument(Which: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IsPosted: Boolean;
    begin
        if HasPostedFilter(IsPosted) and IsPosted then
            exit(false);

        SetSalesHeaderFilters(SalesHeader);
        if SalesHeader.Find(Which) then begin
            SetSalesHeaderAsRec(SalesHeader);
            exit(true);
        end;

        if (StrPos(Which, '<') > 0) and (StrPos(Which, '>') = 0) then // We are only interested in unposted docs previous to this one
            exit(false); // since there are none, we should exit

        if HasPostedFilter(IsPosted) and (not IsPosted) then
            exit(false);  // do not attempt search for posted doc

        if HideInvoices then
            exit(false);

        // Get the first posted doc since we no longer have any unposted docs
        SetSalesInvoiceHeaderFilters(SalesInvoiceHeader);
        if SalesInvoiceHeader.FindFirst then begin
            SetSalesInvoiceHeaderAsRec(SalesInvoiceHeader);
            exit(true);
        end;

        exit(false);
    end;

    procedure FindPostedDocument(Which: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        IsPosted: Boolean;
    begin
        if HideInvoices then
            exit;

        if (not HasPostedFilter(IsPosted)) or IsPosted then begin
            SetSalesInvoiceHeaderFilters(SalesInvoiceHeader);
            if SalesInvoiceHeader.Find(Which) then begin
                SetSalesInvoiceHeaderAsRec(SalesInvoiceHeader);
                exit(true);
            end;
        end;

        if HasPostedFilter(IsPosted) and IsPosted then
            exit(false); // do not attempt search for unposted doc

        // If Which contains '<' or is '+' then we should look for the last Sales Header because there are no posted invoices
        // that match the specified criteria.
        if (StrPos(Which, '<') > 0) or (Which = '+') then begin
            SetSalesHeaderFilters(SalesHeader);
            if SalesHeader.FindLast then begin
                SetSalesHeaderAsRec(SalesHeader);
                exit(true);
            end;
        end;

        // No match
        exit(false);
    end;

    local procedure GetNextUnpostedDocument(Steps: Integer): Integer
    var
        SalesHeader: Record "Sales Header";
        IsPosted: Boolean;
        SalesHeaderResults: Integer;
    begin
        if HasPostedFilter(IsPosted) and IsPosted then
            exit(0);

        SetSalesHeaderFilters(SalesHeader);
        SalesHeaderResults := SalesHeader.Next(Steps);

        if SalesHeaderResults <> 0 then
            SetSalesHeaderAsRec(SalesHeader);

        exit(SalesHeaderResults);
    end;

    local procedure GetPreviousUnpostedDocument(Steps: Integer): Integer
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderResults: Integer;
        IsPosted: Boolean;
    begin
        if Steps >= 0 then
            exit(0); // there must be negative steps

        if HasPostedFilter(IsPosted) and IsPosted then
            exit(0);

        SetSalesHeaderFilters(SalesHeader);

        if not SalesHeader.Find('+') then // step 1 entry back (i.e. get the last sales header)
            exit(0); // no previous sales header

        if Steps < -1 then // there are more steps to do
            SalesHeaderResults := SalesHeader.Next(Steps + 1) - 1
        else
            SalesHeaderResults := Steps;

        if SalesHeaderResults <> 0 then
            SetSalesHeaderAsRec(SalesHeader);

        exit(SalesHeaderResults);
    end;

    local procedure HasPostedFilter(var FilterValue: Boolean): Boolean
    var
        PostedFilter: Boolean;
    begin
        if GetFilter(Posted) = '' then
            exit(false);

        if not Evaluate(PostedFilter, GetFilter(Posted)) then
            exit(false);

        FilterValue := PostedFilter;
        exit(true);
    end;

    local procedure SetSalesInvoiceHeaderKey(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if SortByDueDate then begin
            SalesInvoiceHeader.SetCurrentKey("Due Date", "Document Date", "No.");
            SalesInvoiceHeader.SetAscending("Due Date", true);
        end else begin
            SalesInvoiceHeader.SetCurrentKey("Document Date", "Due Date", "No.");
            SalesInvoiceHeader.SetAscending("Due Date", false);
        end;
        SalesInvoiceHeader.SetAscending("Document Date", false);
        SalesInvoiceHeader.SetAscending("No.", false);
    end;

    local procedure SetSalesHeaderKey(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetCurrentKey("Document Date", "No.");
        SalesHeader.SetAscending("No.", false);
        SalesHeader.SetAscending("Document Date", false);
    end;

    procedure SetSortByDocDate()
    begin
        SortByDueDate := false;
    end;

    procedure SetSortByDueDate()
    begin
        SortByDueDate := true;
    end;

    local procedure QuoteIsExpired(): Boolean
    begin
        exit(("Quote Valid Until Date" <> 0D) and ("Quote Valid Until Date" < WorkDate));
    end;

    procedure OpenDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Posted then begin
            if not SalesInvoiceHeader.Get("No.") then
                exit;
            SalesInvoiceHeader.SetRecFilter;
            PAGE.Run(PAGE::"BC O365 Posted Sales Invoice", SalesInvoiceHeader);
        end else begin
            if not SalesHeader.Get("Document Type", "No.") then
                exit;
            SalesHeader.SetRecFilter;
            case "Document Type" of
                "Document Type"::Invoice:
                    PAGE.Run(PAGE::"BC O365 Sales Invoice", SalesHeader);
                "Document Type"::Quote:
                    PAGE.Run(PAGE::"BC O365 Sales Quote", SalesHeader);
            end;
        end;
    end;

    procedure IgnoreInvoices()
    begin
        HideInvoices := true;
    end;
}

