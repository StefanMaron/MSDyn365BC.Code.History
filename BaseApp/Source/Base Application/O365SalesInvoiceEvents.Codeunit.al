codeunit 2162 "O365 Sales Invoice Events"
{
    Permissions = TableData "Calendar Event" = rimd;
    TableNo = "Calendar Event";

    trigger OnRun()
    begin
        if not IsInvoicing then begin
            Result := NotInvoicingErr;
            State := State::Failed;
            exit;
        end;

        ParseEvent(Rec);
    end;

    var
        InvoicePostedMsg: Label 'Invoice %1 was posted.', Comment = '%1=The invoice number';
        InvoicePaidMsg: Label 'Invoice %1 was paid.', Comment = '%1=The invoice number';
        InvoiceOverdueMsg: Label 'Invoice %1 is overdue.', Comment = '%1=The invoice number';
        KpiUpdateMsg: Label 'The KPIs were updated.';
        InvoiceDraftMsg: Label 'There are unsent invoices.';
        InvoiceInactivityMsg: Label 'No invoices have been sent recently.';
        UnsupportedTypeErr: Label 'This event type is not supported.';
        NotInvoicingErr: Label 'This event is only handled for Invoicing.';
        InvoiceEmailFailedMsg: Label 'Invoice %1 could not be sent.', Comment = '%1=The invoice number';
        EstimateEmailFailedMsg: Label 'Estimate %1 could not be sent.', Comment = '%1=The estimate number';

    local procedure ParseEvent(CalendarEvent: Record "Calendar Event")
    var
        O365SalesEvent: Record "O365 Sales Event";
        O365SalesWebService: Codeunit "O365 Sales Web Service";
    begin
        O365SalesEvent.LockTable();
        O365SalesEvent.Get(CalendarEvent."Record ID to Process");

        case O365SalesEvent.Type of
            O365SalesEvent.Type::"Invoice Sent":
                begin
                    O365SalesWebService.SendInvoiceCreatedEvent(O365SalesEvent."Document No.");
                    O365SalesWebService.SendKPI;
                end;
            O365SalesEvent.Type::"Invoice Email Failed":
                O365SalesWebService.SendInvoiceEmailFailedEvent(O365SalesEvent."Document No.");
            O365SalesEvent.Type::"Invoice Paid":
                begin
                    O365SalesWebService.SendInvoicePaidEvent(O365SalesEvent."Document No.");
                    O365SalesWebService.SendKPI;
                end;
            O365SalesEvent.Type::"Draft Reminder":
                O365SalesWebService.SendInvoiceDraftEvent;
            O365SalesEvent.Type::"Invoice Overdue":
                begin
                    O365SalesWebService.SendInvoiceOverdueEvent(O365SalesEvent."Document No.");
                    O365SalesWebService.SendKPI;
                end;
            O365SalesEvent.Type::"Invoicing Inactivity":
                O365SalesWebService.SendInvoiceInactivityEvent;
            O365SalesEvent.Type::"KPI Update":
                O365SalesWebService.SendKPI;
            else
                Error(UnsupportedTypeErr);
        end;
    end;

    local procedure UpdateDraftEvent()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        CalendarEvent: Record "Calendar Event";
        SalesHeader: Record "Sales Header";
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
        NewDate: Date;
        EventNo: Integer;
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        NewDate := CalcDate(StrSubstNo('<%1D>', O365C2GraphEventSettings."Inv. Draft Duration (Day)"), Today);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        if CalendarEvent.Get(O365C2GraphEventSettings."Inv. Draft Event") and (not CalendarEvent.Archived) then begin
            if SalesHeader.IsEmpty then
                CalendarEvent.Delete(true)
            else begin
                CalendarEvent.Validate("Scheduled Date", NewDate);
                CalendarEvent.Modify(true);
            end;

            exit;
        end;

        if SalesHeader.IsEmpty then
            exit;

        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Draft Reminder", '');
        EventNo :=
          CalendarEventMangement.CreateCalendarEvent(
            NewDate, InvoiceDraftMsg, CODEUNIT::"O365 Sales Invoice Events", O365SalesEvent.RecordId,
            O365C2GraphEventSettings."Inv. Draft Enabled");

        O365C2GraphEventSettings."Inv. Draft Event" := EventNo;
        O365C2GraphEventSettings.Modify(true);
    end;

    local procedure UpdateInactivityEvent()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        CalendarEvent: Record "Calendar Event";
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
        NewDate: Date;
        EventNo: Integer;
    begin
        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        NewDate := CalcDate(StrSubstNo('<%1D>', O365C2GraphEventSettings."Inv. Inactivity Duration (Day)"), Today);

        if CalendarEvent.Get(O365C2GraphEventSettings."Inv. Inactivity Event") and (not CalendarEvent.Archived) then begin
            CalendarEvent.Validate("Scheduled Date", NewDate);
            CalendarEvent.Modify(true);
            exit;
        end;

        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Invoicing Inactivity", '');
        EventNo :=
          CalendarEventMangement.CreateCalendarEvent(
            NewDate, InvoiceInactivityMsg, CODEUNIT::"O365 Sales Invoice Events", O365SalesEvent.RecordId,
            O365C2GraphEventSettings."Inv. Inactivity Enabled");

        O365C2GraphEventSettings."Inv. Inactivity Event" := EventNo;
        O365C2GraphEventSettings.Modify(true);
    end;

    local procedure CreateSendEvent(DocNo: Code[20])
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Invoice Sent", DocNo);
        CalendarEventMangement.CreateCalendarEvent(
          Today, StrSubstNo(InvoicePostedMsg, DocNo), CODEUNIT::"O365 Sales Invoice Events", O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Sent"));
    end;

    local procedure CreateOverdueEvent(DocNo: Code[20]; DueDate: Date)
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Invoice Overdue", DocNo);
        CalendarEventMangement.CreateCalendarEvent(
          DueDate, StrSubstNo(InvoiceOverdueMsg, DocNo), CODEUNIT::"O365 Sales Invoice Events", O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Overdue"));
    end;

    local procedure CreatePaidEvent(DocNo: Code[20])
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Invoice Paid", DocNo);
        CalendarEventMangement.CreateCalendarEvent(
          Today, StrSubstNo(InvoicePaidMsg, DocNo), CODEUNIT::"O365 Sales Invoice Events",
          O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Paid"));
    end;

    local procedure CreateKpiEvent()
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"KPI Update", '');
        CalendarEventMangement.CreateCalendarEvent(Today, KpiUpdateMsg, CODEUNIT::"O365 Sales Invoice Events", O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"KPI Update"));
    end;

    local procedure CreateEmailFailedEventEstimate(DocNo: Code[20])
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Estimate Email Failed", DocNo);
        CalendarEventMangement.CreateCalendarEvent(
          Today, StrSubstNo(EstimateEmailFailedMsg, DocNo), CODEUNIT::"O365 Sales Quote Events",
          O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Estimate Email Failed"));
    end;

    local procedure CreateEmailFailedEventInvoice(DocNo: Code[20])
    var
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
    begin
        CreateEvent(O365SalesEvent, O365SalesEvent.Type::"Invoice Email Failed", DocNo);
        CalendarEventMangement.CreateCalendarEvent(
          Today, StrSubstNo(InvoiceEmailFailedMsg, DocNo), CODEUNIT::"O365 Sales Invoice Events",
          O365SalesEvent.RecordId,
          O365SalesEvent.IsEventTypeEnabled(O365SalesEvent.Type::"Invoice Email Failed"));
    end;

    local procedure CreateEvent(var O365SalesEvent: Record "O365 Sales Event"; Type: Integer; DocNo: Code[20])
    begin
        O365SalesEvent.Init();
        O365SalesEvent.Type := Type;
        O365SalesEvent."Document No." := DocNo;
        O365SalesEvent.Insert();
    end;

    local procedure IsInvoice(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        exit(SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice);
    end;

    local procedure IsInvoicing(): Boolean
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        O365SalesEvent: Record "O365 Sales Event";
    begin
        if not O365SalesInitialSetup.ReadPermission then
            exit(false);

        if not (O365C2GraphEventSettings.ReadPermission and O365C2GraphEventSettings.WritePermission) then
            exit(false);

        if not (O365SalesEvent.ReadPermission and O365SalesEvent.WritePermission) then
            exit(false);

        if not O365SalesInitialSetup.Get then
            exit(false);

        exit(O365SalesInitialSetup."Is initialized");
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterPostSalesDoc', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    begin
        if not IsInvoicing then
            exit;

        if not IsInvoice(SalesHeader) then begin
            CreateKpiEvent;
            exit;
        end;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then
            exit;

        // Queue/update Events
        CreateSendEvent(SalesInvHdrNo);
        CreateOverdueEvent(SalesInvHdrNo, SalesHeader."Due Date");
        UpdateDraftEvent;
        UpdateInactivityEvent;
    end;

    [EventSubscriber(ObjectType::Table, 379, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertDetailedCustLedgEntry(var Rec: Record "Detailed Cust. Ledg. Entry"; RunTrigger: Boolean)
    var
        O365SalesEvent: Record "O365 Sales Event";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CalendarEvent: Record "Calendar Event";
    begin
        if Rec.IsTemporary then
            exit;

        if Rec."Initial Document Type" <> Rec."Document Type"::Invoice then
            exit;

        if Rec."Document Type" <> Rec."Document Type"::Payment then
            exit;

        if not IsInvoicing then
            exit;

        SalesInvoiceHeader.SetAutoCalcFields(Cancelled, Closed, Corrective, "Remaining Amount");
        SalesInvoiceHeader.SetRange("Cust. Ledger Entry No.", Rec."Cust. Ledger Entry No.");
        if not SalesInvoiceHeader.FindFirst then
            exit;

        if SalesInvoiceHeader.Cancelled then
            exit;

        if SalesInvoiceHeader.Corrective then
            exit;

        if not SalesInvoiceHeader.Closed then
            exit;

        // Verify paid
        if SalesInvoiceHeader."Remaining Amount" > 0 then begin
            CreateKpiEvent;
            exit;
        end;

        CreatePaidEvent(SalesInvoiceHeader."No.");

        // Remove overdue event
        O365SalesEvent.SetRange(Type, O365SalesEvent.Type::"Invoice Overdue");
        O365SalesEvent.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not O365SalesEvent.FindFirst then
            exit;

        CalendarEvent.SetRange("Record ID to Process", O365SalesEvent.RecordId);
        if CalendarEvent.FindFirst then
            if not CalendarEvent.Archived then
                CalendarEvent.Delete(true);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterSalesHeaderInsert(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not IsInvoice(Rec) then
            exit;

        if not IsInvoicing then
            exit;

        UpdateDraftEvent;
        UpdateInactivityEvent;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterSalesHeaderDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not IsInvoice(Rec) then
            exit;

        if not IsInvoicing then
            exit;

        UpdateDraftEvent;
    end;

    [EventSubscriber(ObjectType::Table, 2158, 'OnBeforeModifyEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeDocumentSentHistoryModify(var Rec: Record "O365 Document Sent History"; var xRec: Record "O365 Document Sent History"; RunTrigger: Boolean)
    begin
        OnInsertOrModifyDocumentSentHistory(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 2158, 'OnAfterInsertEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterDocumentSentHistoryInsert(var Rec: Record "O365 Document Sent History"; RunTrigger: Boolean)
    begin
        OnInsertOrModifyDocumentSentHistory(Rec);
    end;

    local procedure OnInsertOrModifyDocumentSentHistory(var O365DocumentSentHistory: Record "O365 Document Sent History")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        O365DocumentSentHistory2: Record "O365 Document Sent History";
    begin
        if O365DocumentSentHistory."Job Last Status" <> O365DocumentSentHistory."Job Last Status"::Error then
            exit;

        if O365DocumentSentHistory.IsTemporary then
            exit;

        if not IsInvoicing then
            exit;

        // If the record existed and had already failed, then don't spam events
        if O365DocumentSentHistory2.Get(O365DocumentSentHistory."Document Type", O365DocumentSentHistory."Document No.",
             O365DocumentSentHistory.Posted, O365DocumentSentHistory."Created Date-Time")
        then
            if O365DocumentSentHistory2."Job Last Status" = O365DocumentSentHistory."Job Last Status" then
                exit;

        if O365DocumentSentHistory.Posted and
           (O365DocumentSentHistory."Document Type" = O365DocumentSentHistory."Document Type"::Invoice)
        then begin
            if not SalesInvoiceHeader.Get(O365DocumentSentHistory."Document No.") then
                exit;

            // If in the meantime an email succedeed, don't send the event
            SalesInvoiceHeader.CalcFields("Last Email Sent Time", "Last Email Sent Status");
            if (SalesInvoiceHeader."Last Email Sent Status" = SalesInvoiceHeader."Last Email Sent Status"::Finished) and
               (SalesInvoiceHeader."Last Email Sent Time" > O365DocumentSentHistory."Created Date-Time")
            then
                exit;

            CreateEmailFailedEventInvoice(O365DocumentSentHistory."Document No.");
        end else
            if (not O365DocumentSentHistory.Posted) and
               (O365DocumentSentHistory."Document Type" = O365DocumentSentHistory."Document Type"::Quote)
            then begin
                if not SalesHeader.Get(SalesHeader."Document Type"::Quote, O365DocumentSentHistory."Document No.") then
                    exit;

                // If in the meantime an email succedeed, don't send the event
                SalesHeader.CalcFields("Last Email Sent Time", "Last Email Sent Status");
                if (SalesHeader."Last Email Sent Status" = SalesHeader."Last Email Sent Status"::Finished) and
                   (SalesHeader."Last Email Sent Time" > O365DocumentSentHistory."Created Date-Time")
                then
                    exit;

                CreateEmailFailedEventEstimate(O365DocumentSentHistory."Document No.");
            end;
    end;
}

