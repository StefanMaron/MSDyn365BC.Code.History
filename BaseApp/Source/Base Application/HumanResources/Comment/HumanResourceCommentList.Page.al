namespace Microsoft.HumanResources.Comment;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;

page 5223 "Human Resource Comment List"
{
    Caption = 'Comment List';
    DataCaptionExpression = Caption(Rec);
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Human Resource Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        EmployeeQualification: Record "Employee Qualification";
        EmployeeRelative: Record "Employee Relative";
        MiscArticleInfo: Record "Misc. Article Information";
        ConfidentialInfo: Record "Confidential Information";
#pragma warning disable AA0074
        Text000: Label 'untitled', Comment = 'it is a caption for empty page';
#pragma warning restore AA0074

    procedure Caption(HRCommentLine: Record "Human Resource Comment Line"): Text
    begin
        case HRCommentLine."Table Name" of
            HRCommentLine."Table Name"::"Employee Absence":
                if EmployeeAbsence.Get(HRCommentLine."Table Line No.") then begin
                    Employee.Get(EmployeeAbsence."Employee No.");
                    exit(
                      Employee."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeAbsence."Cause of Absence Code" + ' ' +
                      Format(EmployeeAbsence."From Date"));
                end;
            HRCommentLine."Table Name"::Employee:
                if Employee.Get(HRCommentLine."No.") then
                    exit(HRCommentLine."No." + ' ' + Employee.FullName());
            HRCommentLine."Table Name"::"Alternative Address":
                if Employee.Get(HRCommentLine."No.") then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      HRCommentLine."Alternative Address Code");
            HRCommentLine."Table Name"::"Employee Qualification":
                if EmployeeQualification.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeQualification."Qualification Code");
            HRCommentLine."Table Name"::"Employee Relative":
                if EmployeeRelative.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeRelative."Relative Code");
            HRCommentLine."Table Name"::"Misc. Article Information":
                if MiscArticleInfo.Get(
                     HRCommentLine."No.", HRCommentLine."Alternative Address Code", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      MiscArticleInfo."Misc. Article Code");
            HRCommentLine."Table Name"::"Confidential Information":
                if ConfidentialInfo.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      ConfidentialInfo."Confidential Code");
        end;
        exit(Text000);
    end;
}

