namespace System.Integration.PowerBI;

using System.Integration;
using System.Security.AccessControl;

/// <summary>
/// Persists information about the reports that Business Central has uploaded to the user's Power BI personal workspace.
/// </summary>
table 6307 "Power BI Report Uploads"
{
    Caption = 'Power BI Report Uploads';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "PBIX BLOB ID"; Guid)
        {
            Caption = 'PBIX BLOB ID';
            DataClassification = CustomerContent;
            Description = 'ID from Default Report table.';
            TableRelation = "Power BI Blob".Id;
        }
        field(2; "Uploaded Report ID"; Guid)
        {
            Caption = 'Uploaded Report ID';
            DataClassification = CustomerContent;
            Description = 'Report''s ID after finishing upload to the PBI workspace.';
        }
        field(3; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'User who the report was uploaded for.';
            TableRelation = User."User Security ID";
        }
        field(4; "Import ID"; Guid)
        {
            Caption = 'Import ID';
            DataClassification = CustomerContent;
            Description = 'ID of in-progress upload request, used for referencing progress later.';
        }
        field(5; "Deployed Version"; Integer)
        {
            Caption = 'Deployed Version';
            DataClassification = CustomerContent;
            Description = 'The version that was uploaded, so we know when to overwrite with newer reports.';
        }
        field(6; "Is Selection Done"; Boolean)
        {
            Caption = 'Is Selection Done';
            DataClassification = CustomerContent;
            Description = 'Whether or not the one-time selection process has been done after uploading.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';

            trigger OnValidate()
            begin
                if Rec."Is Selection Done" then
                    Rec."Report Upload Status" := Rec."Report Upload Status"::Completed;
            end;
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(7; "Embed Url"; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'The field has been extended to a bigger field. Use "Report Embed Url" field instead.';
            Caption = 'Embed Url';
            DataClassification = CustomerContent;
            Description = 'URL to cache when selecting the reporting.';
            ObsoleteTag = '19.0';
        }
        field(8; "Should Retry"; Boolean)
        {
            Caption = 'Should Retry';
            DataClassification = CustomerContent;
            Description = 'Whether or not we expect the upload to succeed if we try again.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';

            trigger OnValidate()
            begin
                if (not Rec."Should Retry") and (Rec."Report Embed Url" = '') then
                    Rec."Report Upload Status" := Rec."Report Upload Status"::Failed;
            end;
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(9; "Retry After"; DateTime)
        {
            Caption = 'Retry After';
            DataClassification = CustomerContent;
            Description = 'The point in time after which it''s ok to retry this upload.';
        }
        field(10; "Needs Deletion"; Boolean)
        {
            Caption = 'Needs Deletion';
            DataClassification = CustomerContent;
            Description = 'Determines if the report needs to be deleted.';
            ObsoleteReason = 'Use Report Upload Status instead to track the upload status.';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';

            trigger OnValidate()
            begin
                if Rec."Needs Deletion" then
                    Rec."Report Upload Status" := Rec."Report Upload Status"::PendingDeletion;
            end;
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(11; IsGP; Boolean)
        {
            Caption = 'IsGP';
            DataClassification = CustomerContent;
            Description = 'Specifies whether a report uses GP or Business Central datasets.';
        }
        field(20; "Report Embed Url"; Text[2048])
        {
            Caption = 'Report Embed Url';
            DataClassification = CustomerContent;
            Description = 'URL to cache when selecting the reporting.';
        }
        field(23; "Report Upload Status"; Enum "Power BI Upload Status")
        {
            Caption = 'Report Upload Status';
            DataClassification = SystemMetadata;
            Description = 'Specifies the stage of the upload process that this report upload reached.';

#if not CLEAN23
            trigger OnValidate()
            begin
                ValidateUploadStatus();
            end;
#endif
        }
    }

    keys
    {
        key(Key1; "PBIX BLOB ID", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN23
    trigger OnInsert()
    begin
        ValidateUploadStatus();
    end;

    trigger OnModify()
    begin
        ValidateUploadStatus();
    end;

    local procedure ValidateUploadStatus()
    begin
        case Rec."Report Upload Status" of
            Rec."Report Upload Status"::PendingDeletion:
                begin
                    Rec."Is Selection Done" := true;
                    Rec."Needs Deletion" := true;
                    Rec."Should Retry" := false;
                    exit;
                end;
            Rec."Report Upload Status"::Completed:
                begin
                    Rec."Is Selection Done" := true;
                    Rec."Needs Deletion" := false;
                    Rec."Should Retry" := false;
                    exit;
                end;
            Rec."Report Upload Status"::Failed,
            Rec."Report Upload Status"::Skipped:
                begin
                    Rec."Is Selection Done" := true;
                    Rec."Needs Deletion" := false;
                    Rec."Should Retry" := false;
                    exit;
                end;
        end;

        Rec."Is Selection Done" := false;
        Rec."Needs Deletion" := false;
        Rec."Should Retry" := true;
    end;
#endif
}
