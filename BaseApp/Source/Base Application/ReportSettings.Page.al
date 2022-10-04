page 1560 "Report Settings"
{
    // RENAME does not work when primary key contains an option field, in this case "Object Type".
    // Therefore DELETE / INSERT is needed as "User Name" is part of the primary key.

    AccessByPermission = TableData "Object Options" = IMD;
    ApplicationArea = Basic, Suite;
    Caption = 'Report Settings';
    InsertAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Object Options";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; "Parameter Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the settings entry.';
                }
                field("Report ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';
                    MinValue = 1;
                    TableRelation = IF ("Object Type" = CONST(Report)) "Report Metadata".ID;
                    ToolTip = 'Specifies the ID of the report that uses the settings.';

                    trigger OnValidate()
                    begin
                        ValidateObjectID();
                        LookupObjectName("Object ID", "Object Type");
                    end;
                }
                field("Report Name"; ReportName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the report that uses the settings.';
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assigned to';
                    Enabled = NOT LastUsed;
                    TableRelation = User."User Name";
                    ToolTip = 'Specifies who can use the report settings. If the field is blank, the settings are available to all users.';

                    trigger OnValidate()
                    begin
                        if "User Name" <> '' then
                            "Public Visible" := false
                        else
                            "Public Visible" := true;
                    end;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Created by';
                    Editable = false;
                    TableRelation = User."User Name";
                    ToolTip = 'Specifies the name of the user who created the settings.';
                }
                field("Public Visible"; Rec."Public Visible")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shared with all users';
                    Enabled = NOT LastUsed;
                    ToolTip = 'Specifies whether the report settings are available to all users or only the user assigned to the settings.';

                    trigger OnValidate()
                    begin
                        if "Public Visible" then
                            "User Name" := ''
                        else
                            "User Name" := "Created By";
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company to which the settings belong.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Image = New;
                ToolTip = 'Create a new report settings entry that sets filters and options for a specific report. ';

                trigger OnAction()
                var
                    ObjectOptions: Record "Object Options";
                    CustomLayoutReporting: Codeunit "Custom Layout Reporting";
                    PickReport: Page "Pick Report";
                    OptionDataTxt: Text;
                begin
                    PickReport.SetReportObjectId("Object ID");
                    if PickReport.RunModal() <> ACTION::OK then
                        exit;

                    PickReport.GetObjectOptions(ObjectOptions);
                    OptionDataTxt := CustomLayoutReporting.GetReportRequestPageParameters(ObjectOptions."Object ID");
                    OptionDataTxt := REPORT.RunRequestPage(ObjectOptions."Object ID", OptionDataTxt);
                    if OptionDataTxt <> '' then begin
                        UpdateOptionData(ObjectOptions, OptionDataTxt);
                        ObjectOptions.Insert(true);
                        Rec := ObjectOptions;
                    end;
                end;
            }
            action(CopySettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                Image = Copy;
                ToolTip = 'Make a copy the selected report settings.';

                trigger OnAction()
                var
                    ObjectOptions: Record "Object Options";
                begin
                    if "Option Data".HasValue() then
                        CalcFields("Option Data");

                    ObjectOptions.TransferFields(Rec);
                    ObjectOptions."Parameter Name" := CopyStr(StrSubstNo(CopyTxt, "Parameter Name"), 1, MaxStrLen(ObjectOptions."Parameter Name"));
                    ObjectOptions.Insert(true);
                end;
            }
            action(EditSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Enabled = NOT LastUsed;
                Image = Edit;
                ToolTip = 'Change the options and filters that are defined for the selected report settings.';

                trigger OnAction()
                var
                    OptionDataTxt: Text;
                begin
                    OptionDataTxt := REPORT.RunRequestPage("Object ID", GetOptionData());
                    if OptionDataTxt <> '' then begin
                        UpdateOptionData(Rec, OptionDataTxt);
                        Modify(true);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(NewSettings_Promoted; NewSettings)
                {
                }
                actionref(CopySettings_Promoted; CopySettings)
                {
                }
                actionref(EditSettings_Promoted; EditSettings)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        LastUsed := "Parameter Name" = LastUsedTxt;
    end;

    trigger OnAfterGetRecord()
    begin
        LookupObjectName("Object ID", "Object Type");
    end;

    var
        CopyTxt: Label 'Copy of %1', Comment = '%1 is the Parameter Name field from the Object Options record';
        LastUsedTxt: Label 'Last used options and filters', Comment = 'Translation must match RequestPageLatestSavedSettingsName from Lang.resx';
        LastUsed: Boolean;
        ObjectIdValidationErr: Label 'The specified object ID is not valid; the object must exist in the application.';
        ReportName: Text;
        EmptyOptionDataErr: Label 'Option Data is empty.';

    local procedure ValidateObjectID()
    var
        AllObj: Record AllObj;
    begin
        if not AllObj.Get("Object Type", "Object ID") then
            Error(ObjectIdValidationErr);
    end;

    local procedure LookupObjectName(ObjectID: Integer; ObjectType: Option)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(ObjectType, ObjectID) then
            ReportName := AllObjWithCaption."Object Caption"
        else
            ReportName := '';
    end;

    local procedure UpdateOptionData(var ObjectOptions: Record "Object Options"; OptionDataTxt: Text)
    var
        OutStream: OutStream;
    begin
        if OptionDataTxt = '' then
            Error(EmptyOptionDataErr);

        Clear(ObjectOptions."Option Data");
        ObjectOptions."Option Data".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(OptionDataTxt);
    end;

    local procedure GetOptionData() Result: Text
    var
        InStream: InStream;
    begin
        if "Option Data".HasValue() then begin
            CalcFields("Option Data");
            "Option Data".CreateInStream(InStream, TEXTENCODING::UTF8);
            InStream.ReadText(Result);
        end;
    end;
}

