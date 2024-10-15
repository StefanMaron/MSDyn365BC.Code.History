table 2158 "O365 Document Sent History"
{
    Caption = 'O365 Document Sent History';
    Permissions = TableData "O365 Document Sent History" = rimd;
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(4; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(7; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor;
        }
        field(11; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
        }
        field(12; "Job Last Status"; Option)
        {
            Caption = 'Job Last Status';
            OptionCaption = ',In Process,Finished,Error';
            OptionMembers = ,"In Process",Finished,Error;
            trigger OnValidate()
            var
                JobQueueLogEntry: Record "Job Queue Log Entry";
            begin
                if "Job Last Status" = "Job Last Status"::"In Process" then
                    Clear("Job Completed")
                else
                    if IsNullGuid("Job Queue Entry ID") then
                        "Job Completed" := CurrentDateTime
                    else begin
                        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
                        JobQueueLogEntry.SetCurrentKey("Entry No.");

                        if JobQueueLogEntry.FindLast() then
                            "Job Completed" := JobQueueLogEntry."End Date/Time"
                        else
                            "Job Completed" := CurrentDateTime;
                    end;
            end;
        }
        field(13; "Job Completed"; DateTime)
        {
            Caption = 'Job Completed';
        }
        field(14; Notified; Boolean)
        {
            Caption = 'Notified';
        }
        field(15; NotificationCleared; Boolean)
        {
            Caption = 'NotificationCleared';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", Posted, "Created Date-Time")
        {
            Clustered = true;
        }
        key(Key2; "Job Queue Entry ID")
        {
        }
    }

    fieldgroups
    {
    }
}

