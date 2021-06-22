codeunit 7037 "Price Source - Job Task" implements "Price Source"
{
    var
        Job: Record Job; // Parent
        JobTask: Record "Job Task";
        ParentErr: Label 'Parent Source No. must be blank for Vendor source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if JobTask.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Parent Source No." := JobTask."Job No.";
            PriceSource."Source No." := JobTask."Job Task No.";
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if VerifyParent(PriceSource) then
            if JobTask.Get(PriceSource."Parent Source No.", PriceSource."Source No.") then
                PriceSource."Source ID" := JobTask.SystemId
            else
                PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    begin
        if Job.Get(PriceSource."Parent Source No.") then;
        if Page.RunModal(Page::"Job List", Job) = ACTION::LookupOK then begin
            PriceSource.Validate("Parent Source No.", Job."No.");
            JobTask.SetRange("Job No.", PriceSource."Parent Source No.");
        end;
        if JobTask.Get(PriceSource."Parent Source No.", PriceSource."Source No.") then;
        if Page.RunModal(Page::"Job Task List", JobTask) = ACTION::LookupOK then begin
            PriceSource.Validate("Parent Source No.", JobTask."Job No.");
            PriceSource.Validate("Source No.", JobTask."Job Task No.");
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        PriceSource.Testfield("Parent Source No.");
        Result := Job.Get(PriceSource."Parent Source No.");
        if not Result then
            PriceSource."Parent Source No." := '';
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
        exit(PriceSource."Parent Source No.");
    end;
}