page 9652 "Report Layout Selection"
{
    AdditionalSearchTerms = 'customization,document layout';
    ApplicationArea = Basic, Suite;
    Caption = 'Report Layout Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Report Layout Selection";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Company)
            {
                Caption = 'Company';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    Importance = Promoted;
                    TableRelation = Company;
                    ToolTip = 'Specifies the name of the company that is used for the report.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the report.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Selected Layout';
                    ToolTip = 'Specifies the report layout that is currently used on the report.';

                    trigger OnValidate()
                    begin
                        UpdateRec;
                        Commit();
                        LookupCustomLayout;
                    end;
                }
                field("Custom Report Layout Code"; "Custom Report Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Custom Report Layout" WHERE("Report ID" = FIELD("Report ID"));
                    ToolTip = 'Specifies the custom report layout.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReportLayoutSelection.Validate("Custom Report Layout Code", ReportLayoutSelection."Custom Report Layout Code");
                        UpdateRec;
                    end;
                }
                field(CustomLayoutDescription; CustomLayoutDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Custom Layout Description';
                    ToolTip = 'Specifies the description for a custom layout that is used by the report when the Selected Layout field is set to Custom.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupCustomLayout;
                    end;

                    trigger OnValidate()
                    var
                        CustomReportLayout2: Record "Custom Report Layout";
                    begin
                        CustomReportLayout2.SetCurrentKey("Report ID", "Company Name", Type);
                        CustomReportLayout2.SetRange("Report ID", ReportLayoutSelection."Report ID");
                        CustomReportLayout2.SetFilter("Company Name", '%1|%2', '', SelectedCompany);
                        CustomReportLayout2.SetFilter(
                          Description, StrSubstNo('@*%1*', CustomLayoutDescription));
                        if not CustomReportLayout2.FindFirst then
                            Error(CouldNotFindCustomReportLayoutErr, CustomLayoutDescription);

                        if CustomReportLayout2.Code <> "Custom Report Layout Code" then begin
                            Validate("Custom Report Layout Code", CustomReportLayout2.Code);
                            UpdateRec;
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Custom Layouts"; "Report Layouts Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Custom Layouts';
                ShowFilter = false;
                SubPageLink = "Report ID" = FIELD("Report ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Customizations)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Custom Layouts';
                Image = "Report";
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Custom Report Layouts";
                RunPageLink = "Report ID" = FIELD("Report ID");
                ToolTip = 'View or edit the custom layouts that are available for a report.';
            }
            action(RunReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Run Report';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Run a test report.';

                trigger OnAction()
                begin
                    REPORT.Run("Report ID");
                end;
            }
            action(BulkUpdate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update All layouts';
                Image = UpdateXML;
                ToolTip = 'Update specific report layouts or all custom report layouts that might be affected by dataset changes.';

                trigger OnAction()
                var
                    DocumentReportMgt: Codeunit "Document Report Mgt.";
                begin
                    DocumentReportMgt.BulkUpgrade(false);
                end;
            }
            action(TestUpdate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Layout Updates';
                Image = TestReport;
                ToolTip = 'Check if there are any updates detected.';

                trigger OnAction()
                var
                    DocumentReportMgt: Codeunit "Document Report Mgt.";
                begin
                    DocumentReportMgt.BulkUpgrade(true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetRec;
    end;

    trigger OnAfterGetRecord()
    begin
        GetRec;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not IsInitialized then
            InitializeData;
        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        SelectedCompany := CompanyName;
    end;

    var
        ReportLayoutSelection: Record "Report Layout Selection";
        SelectedCompany: Text[30];
        WrongCompanyErr: Label 'You cannot select a layout that is specific to another company.';
        CustomLayoutDescription: Text;
        IsInitialized: Boolean;
        CouldNotFindCustomReportLayoutErr: Label 'There is no custom report layout with %1 in the description.', Comment = '%1 Description of custom report layout';

    procedure UpdateRec()
    begin
        if ReportLayoutSelection.Get("Report ID", SelectedCompany) then begin
            ReportLayoutSelection := Rec;
            ReportLayoutSelection."Report Name" := '';
            ReportLayoutSelection."Company Name" := SelectedCompany;
            OnUpdateRecOnBeforeModify(ReportLayoutSelection, Rec, SelectedCompany);
            ReportLayoutSelection.Modify();
        end else begin
            Clear(ReportLayoutSelection);
            ReportLayoutSelection := Rec;
            ReportLayoutSelection."Report Name" := '';
            ReportLayoutSelection."Company Name" := SelectedCompany;
            OnUpdateRecOnBeforeInsert(ReportLayoutSelection, Rec, SelectedCompany);
            ReportLayoutSelection.Insert(true);
        end;
    end;

    local procedure GetRec()
    begin
        if not Get("Report ID", '') then
            exit;
        if not ReportLayoutSelection.Get("Report ID", SelectedCompany) then begin
            ReportLayoutSelection.Init();
            ReportLayoutSelection.Type := GetDefaultType("Report ID");
        end;
        Type := ReportLayoutSelection.Type;
        "Custom Report Layout Code" := ReportLayoutSelection."Custom Report Layout Code";
        CalcFields("Report Layout Description");
        CustomLayoutDescription := "Report Layout Description";
        OnGetRecOnBeforeModify(Rec, SelectedCompany);
        Modify;
    end;

    local procedure LookupCustomLayout()
    begin
        if Type <> Type::"Custom Layout" then
            exit;

        if not SelectReportLayout then
            exit;

        GetRec;
        if (Type = Type::"Custom Layout") and
           ("Custom Report Layout Code" = '')
        then begin
            Validate(Type, GetDefaultType("Report ID"));
            UpdateRec;
        end;
        CurrPage.Update(false);
    end;

    local procedure SelectReportLayout(): Boolean
    var
        CustomReportLayout2: Record "Custom Report Layout";
        OK: Boolean;
    begin
        CustomReportLayout2.FilterGroup(4);
        CustomReportLayout2.SetRange("Report ID", "Report ID");
        CustomReportLayout2.FilterGroup(0);
        CustomReportLayout2.SetFilter("Company Name", '%1|%2', SelectedCompany, '');
        OK := PAGE.RunModal(PAGE::"Custom Report Layouts", CustomReportLayout2) = ACTION::LookupOK;
        if OK then begin
            if CustomReportLayout2.Find then begin
                if not (CustomReportLayout2."Company Name" in [SelectedCompany, '']) then
                    Error(WrongCompanyErr);
                "Custom Report Layout Code" := CustomReportLayout2.Code;
                Type := Type::"Custom Layout";
                UpdateRec;
            end
        end else
            if Type = Type::"Custom Layout" then
                if CustomReportLayout2.IsEmpty then begin
                    Type := GetDefaultType("Report ID");
                    "Custom Report Layout Code" := '';
                    UpdateRec;
                end;
        exit(OK);
    end;

    local procedure InitializeData()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.SetRange(ProcessingOnly, false);
        if ReportMetadata.FindSet then
            repeat
                Init;
                "Report ID" := ReportMetadata.ID;
                "Report Name" := ReportMetadata.Caption;
                Insert;
            until ReportMetadata.Next = 0;
        if FindFirst then;
        IsInitialized := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRecOnBeforeModify(var ReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeInsert(var ToReportLayoutSelection: Record "Report Layout Selection"; FromReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeModify(var ToReportLayoutSelection: Record "Report Layout Selection"; FromReportLayoutSelection: Record "Report Layout Selection"; SelectedCompany: Text[30])
    begin
    end;
}

