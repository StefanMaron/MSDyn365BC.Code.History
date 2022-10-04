table 2163 "O365 Sales Event"
{
    Caption = 'O365 Sales Event';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Invoice Sent,Invoice Paid,Draft Reminder,Invoice Overdue,Invoicing Inactivity,Estimate Sent,Estimate Accepted,Estimate Expiring,Invoice Email Failed,Estimate Email Failed,KPI Update';
            OptionMembers = "Invoice Sent","Invoice Paid","Draft Reminder","Invoice Overdue","Invoicing Inactivity","Estimate Sent","Estimate Accepted","Estimate Expiring","Invoice Email Failed","Estimate Email Failed","KPI Update";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
    }

    keys
    {
        key(Key1; "No.", Type, "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure IsEventTypeEnabled(EventType: Integer): Boolean
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        O365SalesEvent: Record "O365 Sales Event";
    begin
        if not O365C2GraphEventSettings.Get() then
            O365C2GraphEventSettings.Insert();

        case EventType of
            O365SalesEvent.Type::"Draft Reminder":
                exit(O365C2GraphEventSettings."Inv. Draft Enabled");
            O365SalesEvent.Type::"Invoice Overdue":
                exit(O365C2GraphEventSettings."Inv. Overdue Enabled");
            O365SalesEvent.Type::"Invoice Paid":
                exit(O365C2GraphEventSettings."Inv. Paid Enabled");
            O365SalesEvent.Type::"Invoice Sent":
                exit(O365C2GraphEventSettings."Inv. Sent Enabled");
            O365SalesEvent.Type::"Invoicing Inactivity":
                exit(O365C2GraphEventSettings."Inv. Inactivity Enabled");
            O365SalesEvent.Type::"Estimate Accepted":
                exit(O365C2GraphEventSettings."Est. Accepted Enabled");
            O365SalesEvent.Type::"Estimate Expiring":
                exit(O365C2GraphEventSettings."Est. Expiring Enabled");
            O365SalesEvent.Type::"Estimate Sent":
                exit(O365C2GraphEventSettings."Est. Sent Enabled");
            O365SalesEvent.Type::"Invoice Email Failed":
                exit(O365C2GraphEventSettings."Inv. Email Failed Enabled");
            O365SalesEvent.Type::"Estimate Email Failed":
                exit(O365C2GraphEventSettings."Est. Email Failed Enabled");
            O365SalesEvent.Type::"KPI Update":
                exit(O365C2GraphEventSettings."Kpi Update Enabled");
        end;

        exit(false);
    end;
#endif
}

