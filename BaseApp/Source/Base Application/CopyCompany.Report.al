report 357 "Copy Company"
{
    Caption = 'Copy Company';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Company; Company)
        {
            DataItemTableView = SORTING(Name);
            dataitem("Experience Tier Setup"; "Experience Tier Setup")
            {
                DataItemLink = "Company Name" = FIELD(Name);
                DataItemTableView = SORTING("Company Name");

                trigger OnAfterGetRecord()
                var
                    ExperienceTierSetup: Record "Experience Tier Setup";
                    ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
                begin
                    ExperienceTierSetup := "Experience Tier Setup";
                    ExperienceTierSetup."Company Name" := NewCompanyName;
                    if ExperienceTierSetup.Insert then;
                    ApplicationAreaMgmt.SetExperienceTierOtherCompany(ExperienceTierSetup, NewCompanyName);
                end;
            }
            dataitem("Report Layout Selection"; "Report Layout Selection")
            {
                DataItemLink = "Company Name" = FIELD(Name);
                DataItemTableView = SORTING("Report ID", "Company Name");

                trigger OnAfterGetRecord()
                var
                    ReportLayoutSelection: Record "Report Layout Selection";
                begin
                    ReportLayoutSelection := "Report Layout Selection";
                    ReportLayoutSelection."Report ID" := "Report ID";
                    ReportLayoutSelection."Company Name" := NewCompanyName;
                    if ReportLayoutSelection.Insert then;
                end;
            }
            dataitem("Custom Report Layout"; "Custom Report Layout")
            {
                DataItemLink = "Company Name" = FIELD(Name);
                DataItemTableView = SORTING("Report ID", "Company Name", Type);

                trigger OnAfterGetRecord()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                begin
                    CustomReportLayout := "Custom Report Layout";
                    CustomReportLayout.Code := '';
                    CustomReportLayout."Company Name" := NewCompanyName;
                    if CustomReportLayout.Insert(true) then;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ProgressWindow.Open(StrSubstNo(ProgressMsg, NewCompanyName));

                if BreakReport then
                    CurrReport.Break;
                CopyCompany(Name, NewCompanyName);
                BreakReport := true;
            end;

            trigger OnPostDataItem()
            begin
                ProgressWindow.Close;
                SetNewNameToNewCompanyInfo;
                SetRecurringJobsOnHold;
                RegisterUpgradeTags(NewCompanyName);
                Message(CopySuccessMsg, Name);
            end;
        }
    }

    requestpage
    {
        ShowFilter = false;

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
                    field("New Company Name"; NewCompanyName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Company Name';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new company. The name can have a maximum of 30 characters. If the database collation is case-sensitive, you can have one company called COMPANY and another called Company. However, if the database is case-insensitive, you cannot create companies with names that differ only by case.';

                        trigger OnValidate()
                        begin
                            NewCompanyName := DelChr(NewCompanyName, '<>');
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ProgressWindow: Dialog;
        BreakReport: Boolean;
        NewCompanyName: Text[30];
        ProgressMsg: Label 'Creating new company %1.', Comment = 'Creating new company Contoso Corporation.';
        CopySuccessMsg: Label 'Company %1 has been copied successfully.', Comment = 'Company CRONUS International Ltd. has been copied successfully.';

    procedure GetCompanyName(): Text[30]
    begin
        exit(NewCompanyName);
    end;

    local procedure RegisterUpgradeTags(CompanyName: Code[30])
    var
        UpgradeTag: codeunit "Upgrade Tag";
    begin
        UpgradeTag.SetAllUpgradeTags(CompanyName);
    end;

    local procedure SetNewNameToNewCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        Company: Record Company;
    begin
        if Company.Get(NewCompanyName) then;
        Company."Display Name" := NewCompanyName;
        Company.Modify;

        if CompanyInformation.ChangeCompany(NewCompanyName) then
            if CompanyInformation.Get then begin
                CompanyInformation.Name := NewCompanyName;
                CompanyInformation.Modify(true);
            end;

        OnAfterSetNewNameToNewCompanyInfo(NewCompanyName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewNameToNewCompanyInfo(NewCompanyName: Text[30])
    begin
    end;

    local procedure SetRecurringJobsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ChangeCompany(NewCompanyName);

        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet(true) then
            repeat
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
                JobQueueEntry.Modify;
            until JobQueueEntry.Next = 0;
    end;
}

