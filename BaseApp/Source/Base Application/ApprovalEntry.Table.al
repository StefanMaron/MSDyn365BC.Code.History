table 454 "Approval Entry"
{
    Caption = 'Approval Entry';
    ReplicateData = true;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Enum "Approval Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(6; "Sender ID"; Code[50])
        {
            Caption = 'Sender ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(7; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(8; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(9; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Open,Canceled,Rejected,Approved';
            OptionMembers = Created,Open,Canceled,Rejected,Approved;

            trigger OnValidate()
            begin
                if (xRec.Status = Status::Created) and (Status = Status::Open) then
                    "Date-Time Sent for Approval" := CreateDateTime(Today, Time);
            end;
        }
        field(10; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
        }
        field(11; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
        }
        field(12; "Last Modified By User ID"; Code[50])
        {
            Caption = 'Last Modified By User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(13; Comment; Boolean)
        {
            CalcFormula = Exist ("Approval Comment Line" WHERE("Table ID" = FIELD("Table ID"),
                                                               "Record ID to Approve" = FIELD("Record ID to Approve"),
                                                               "Workflow Step Instance ID" = FIELD("Workflow Step Instance ID")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(15; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(18; "Approval Type"; Option)
        {
            Caption = 'Approval Type';
            OptionCaption = 'Workflow User Group,Sales Pers./Purchaser,Approver';
            OptionMembers = "Workflow User Group","Sales Pers./Purchaser",Approver;
        }
        field(19; "Limit Type"; Option)
        {
            Caption = 'Limit Type';
            OptionCaption = 'Approval Limits,Credit Limits,Request Limits,No Limits';
            OptionMembers = "Approval Limits","Credit Limits","Request Limits","No Limits";
        }
        field(20; "Available Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Available Credit Limit (LCY)';
        }
        field(21; "Pending Approvals"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Record ID to Approve" = FIELD("Record ID to Approve"),
                                                        Status = FILTER(Created | Open),
                                                        "Workflow Step Instance ID" = FIELD("Workflow Step Instance ID")));
            Caption = 'Pending Approvals';
            FieldClass = FlowField;
        }
        field(22; "Record ID to Approve"; RecordID)
        {
            Caption = 'Record ID to Approve';
            DataClassification = SystemMetadata;
        }
        field(23; "Delegation Date Formula"; DateFormula)
        {
            Caption = 'Delegation Date Formula';
        }
        field(26; "Number of Approved Requests"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Record ID to Approve" = FIELD("Record ID to Approve"),
                                                        Status = FILTER(Approved),
                                                        "Workflow Step Instance ID" = FIELD("Workflow Step Instance ID")));
            Caption = 'Number of Approved Requests';
            FieldClass = FlowField;
        }
        field(27; "Number of Rejected Requests"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Record ID to Approve" = FIELD("Record ID to Approve"),
                                                        Status = FILTER(Rejected),
                                                        "Workflow Step Instance ID" = FIELD("Workflow Step Instance ID")));
            Caption = 'Number of Rejected Requests';
            FieldClass = FlowField;
        }
        field(29; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(30; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(31; "Related to Change"; Boolean)
        {
            CalcFormula = Exist ("Workflow - Record Change" WHERE("Workflow Step Instance ID" = FIELD("Workflow Step Instance ID"),
                                                                  "Record ID" = FIELD("Record ID to Approve")));
            Caption = 'Related to Change';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Record ID to Approve", "Workflow Step Instance ID", "Sequence No.")
        {
        }
        key(Key3; "Table ID", "Document Type", "Document No.", "Sequence No.", "Record ID to Approve")
        {
        }
        key(Key4; "Approver ID", Status, "Due Date", "Date-Time Sent for Approval")
        {
        }
        key(Key5; "Sender ID")
        {
        }
        key(Key6; "Due Date")
        {
        }
        key(Key7; "Table ID", "Record ID to Approve", Status, "Workflow Step Instance ID", "Sequence No.")
        {
        }
        key(Key8; "Table ID", "Document Type", "Document No.", "Date-Time Sent for Approval")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange(Type, NotificationEntry.Type::Approval);
        NotificationEntry.SetRange("Triggered By Record", RecordId);
        NotificationEntry.DeleteAll(true);
    end;

    trigger OnModify()
    begin
        "Last Date-Time Modified" := CreateDateTime(Today, Time);
        "Last Modified By User ID" := UserId;
    end;

    var
        PageManagement: Codeunit "Page Management";
        RecNotExistTxt: Label 'The record does not exist.';
        ChangeRecordDetailsTxt: Label '; %1 changed from %2 to %3', Comment = 'Prefix = Record information %1 = field caption %2 = old value %3 = new value. Example: Customer 123455; Credit Limit changed from 100.00 to 200.00';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowRecord()
    var
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Record ID to Approve") then
            exit;
        RecRef.SetRecFilter;
        PageManagement.PageRun(RecRef);
    end;

    procedure RecordCaption(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RecRef: RecordRef;
        PageNo: Integer;
    begin
        if not RecRef.Get("Record ID to Approve") then
            exit;
        PageNo := PageManagement.GetPageID(RecRef);
        if PageNo = 0 then
            exit;
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, PageNo);
        exit(StrSubstNo('%1 %2', AllObjWithCaption."Object Caption", "Document No."));
    end;

    procedure RecordDetails() Details: Text
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        RecRef: RecordRef;
        ChangeRecordDetails: Text;
    begin
        if not RecRef.Get("Record ID to Approve") then
            exit(RecNotExistTxt);

        ChangeRecordDetails := GetChangeRecordDetails;

        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SalesHeader.CalcFields(Amount);
                    Details :=
                      StrSubstNo(
                        '%1 ; %2: %3', SalesHeader."Sell-to Customer Name", SalesHeader.FieldCaption(Amount), SalesHeader.Amount);
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchHeader);
                    PurchHeader.CalcFields(Amount);
                    Details :=
                      StrSubstNo(
                        '%1 ; %2: %3', PurchHeader."Buy-from Vendor Name", PurchHeader.FieldCaption(Amount), PurchHeader.Amount);
                end;
            else
                Details := Format("Record ID to Approve", 0, 1) + ChangeRecordDetails;
        end;

        OnAfterGetRecordDetails(RecRef, ChangeRecordDetails, Details);
    end;

    procedure IsOverdue(): Boolean
    begin
        exit((Status in [Status::Created, Status::Open]) and ("Due Date" < Today));
    end;

    procedure GetCustVendorDetails(var CustVendorNo: Code[20]; var CustVendorName: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Record ID to Approve") then
            exit;

        case "Table ID" of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    CustVendorNo := PurchaseHeader."Pay-to Vendor No.";
                    CustVendorName := PurchaseHeader."Pay-to Name";
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    CustVendorNo := SalesHeader."Bill-to Customer No.";
                    CustVendorName := SalesHeader."Bill-to Name";
                end;
            DATABASE::Customer:
                begin
                    RecRef.SetTable(Customer);
                    CustVendorNo := Customer."No.";
                    CustVendorName := Customer.Name;
                end;
            else
        end;

        OnAfterGetCustVendorDetails(Rec, CustVendorNo, CustVendorName);
    end;

    procedure GetChangeRecordDetails() ChangeDetails: Text
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
        OldValue: Text;
        NewValue: Text;
    begin
        WorkflowRecordChange.SetRange("Record ID", "Record ID to Approve");
        WorkflowRecordChange.SetRange("Workflow Step Instance ID", "Workflow Step Instance ID");

        if WorkflowRecordChange.FindSet then
            repeat
                WorkflowRecordChange.CalcFields("Field Caption");
                NewValue := WorkflowRecordChange.GetFormattedNewValue(true);
                OldValue := WorkflowRecordChange.GetFormattedOldValue(true);
                ChangeDetails += StrSubstNo(ChangeRecordDetailsTxt, WorkflowRecordChange."Field Caption",
                    OldValue, NewValue);
            until WorkflowRecordChange.Next = 0;
    end;

    procedure CanCurrentUserEdit(): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit(false);
        exit((UserSetup."User ID" in ["Sender ID", "Approver ID"]) or UserSetup."Approval Administrator");
    end;

    procedure MarkAllWhereUserisApproverOrSender()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) and UserSetup."Approval Administrator" then
            exit;
        FilterGroup(-1); // Used to support the cross-column search
        SetRange("Approver ID", UserId);
        SetRange("Sender ID", UserId);
        if FindSet then
            repeat
                Mark(true);
            until Next = 0;
        MarkedOnly(true);
        FilterGroup(0);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterGetRecordDetails(RecRef: RecordRef; ChangeRecordDetails: Text; var Details: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustVendorDetails(var ApprovalEntry: Record "Approval Entry"; var CustVendorNo: Code[20]; var CustVendorName: Text[100])
    begin
    end;
}

