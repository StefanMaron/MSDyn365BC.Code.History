namespace System.AI;

using System.Environment;

table 2002 "Azure Machine Learning Usage"
{
    // // This table is used for Azure Machine Learning related features to control that amount of time used by all
    // // these features in total does not exceed the limit defined by Azure ML.The table is singleton and used only in SaaS.

    Caption = 'Azure Machine Learning Usage';
    ObsoleteReason = 'Table 2003 replaces this.';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Total Processing Time"; Decimal)
        {
            Caption = 'Total Processing Time';
            Description = 'Processing time of the all Azure ML requests is in seconds for current month.';
            Editable = false;
            MinValue = 0;
        }
        field(3; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
            Description = 'Date when the table was updated last time.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        EnvironmentInfo: Codeunit "Environment Information";
        ProcessingTimeLessThanZeroErr: Label 'The provided Azure ML processing time is less or equal to zero.';

    procedure IncrementTotalProcessingTime(AzureMLServiceProcessingTime: Decimal)
    begin
        if AzureMLServiceProcessingTime <= 0 then
            Error(ProcessingTimeLessThanZeroErr);

        if GetSingleInstance() then begin
            "Total Processing Time" += AzureMLServiceProcessingTime;
            "Last Date Updated" := Today;
            Modify(true);
        end;
    end;

    procedure IsAzureMLLimitReached(AzureMLUsageLimit: Decimal): Boolean
    begin
        if GetSingleInstance() then
            if GetTotalProcessingTime() >= AzureMLUsageLimit then
                exit(true);
        exit(false);
    end;

    procedure GetTotalProcessingTime(): Decimal
    begin
        // in case Azure ML is used by other features processing time should be added here
        if GetSingleInstance() then
            exit("Total Processing Time");
    end;

    procedure GetSingleInstance(): Boolean
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit(false);
        if not FindFirst() then begin
            Init();
            "Last Date Updated" := Today;
            Insert();
        end;

        // reset total processing time when new month starts
        if Date2DMY(Today, 2) <> Date2DMY("Last Date Updated", 2) then begin
            "Total Processing Time" := 0;
            Modify();
        end;
        exit(true);
    end;
}

