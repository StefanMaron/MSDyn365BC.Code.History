table 458 "Overdue Approval Entry"
{
    Caption = 'Overdue Approval Entry';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order, ';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"," ";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Table ID" = CONST(36)) "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF ("Table ID" = CONST(38)) "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(4; "Sent to ID"; Code[50])
        {
            Caption = 'Sent to ID';
            TableRelation = "User Setup";
        }
        field(5; "Sent Time"; Time)
        {
            Caption = 'Sent Time';
        }
        field(6; "Sent Date"; Date)
        {
            Caption = 'Sent Date';
        }
        field(7; "E-Mail"; Text[100])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(8; "Sent to Name"; Text[30])
        {
            Caption = 'Sent to Name';
        }
        field(9; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(11; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(12; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(13; "Approval Type"; Option)
        {
            Caption = 'Approval Type';
            OptionCaption = 'Workflow User Group,Sales Pers./Purchaser,Approver';
            OptionMembers = "Workflow User Group","Sales Pers./Purchaser",Approver;
        }
        field(14; "Limit Type"; Option)
        {
            Caption = 'Limit Type';
            OptionCaption = 'Approval Limits,Credit Limits,Request Limits,No Limits';
            OptionMembers = "Approval Limits","Credit Limits","Request Limits","No Limits";
        }
        field(15; "Record ID to Approve"; RecordID)
        {
            Caption = 'Record ID to Approve';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Document Type", "Document No.", "Sequence No.", "Sent Date", "Sent Time", "Record ID to Approve")
        {
            Clustered = true;
        }
        key(Key2; "Approver ID")
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
        NotificationEntry.SetRange(Type, NotificationEntry.Type::Overdue);
        NotificationEntry.SetRange("Triggered By Record", RecordId);
        NotificationEntry.DeleteAll(true);
    end;

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Record ID to Approve") then
            exit;
        PageManagement.PageRun(RecRef);
    end;
}

