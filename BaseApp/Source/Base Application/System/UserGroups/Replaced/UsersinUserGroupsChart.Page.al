#if not CLEAN22
namespace System.Security.AccessControl;

using System.Integration;
using System.Visualization;

page 773 "Users in User Groups Chart"
{
    Caption = 'Users in User Groups';
    PageType = CardPart;
    SourceTable = "Business Chart Buffer";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the Security Group Members Chart page in the security groups system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status Text';
                ShowCaption = false;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(Point: JsonObject)
                var
                    UserGroupMember: Record "User Group Member";
                begin
                    UserGroupMember.SetRange("User Group Code", GetUserGroupCode(Point));
                    if not UserGroupMember.FindFirst() then
                        exit;
                    PAGE.RunModal(PAGE::"User Group Members", UserGroupMember);
                    CurrPage.Update(); // refresh the charts with the eventual changes
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    if IsChartDataReady then
                        UpdateChart();
                end;

                trigger Refresh()
                begin
                    if IsChartDataReady then
                        UpdateChart();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        UpdateChart();
        IsChartDataReady := true;
    end;

    var
        StatusText: Text[250];
        IsChartDataReady: Boolean;
        UsersTxt: Label 'Users';
        UserGroupTxt: Label 'User Group';
        XValueStringTok: Label 'XValueString', Locked = true;

    local procedure GetUserGroupCode(Point: JsonObject): Text[249]
    var
        Token: JsonToken;
        XValueString: Text[249];
    begin
        Point.Get(XValueStringTok, Token);
        XValueString := CopyStr(Token.AsValue().AsText(), 1, 249);
        exit(XValueString);
    end;

    local procedure UpdateChart()
    begin
        UpdateData();
        Rec.UpdateChart(CurrPage.BusinessChart);
    end;

    local procedure UpdateData()
    var
        UsersInUserGroups: Query "Users in User Groups";
        ColumnNumber: Integer;
    begin
        Rec.Initialize(); // Initialize .NET variables for the chart

        // Define Y-Axis
        Rec.AddIntegerMeasure(UsersTxt, 1, Rec."Chart Type"::Column);

        // Define X-Axis
        Rec.SetXAxis(UserGroupTxt, Rec."Data Type"::String);

        if not UsersInUserGroups.Open() then
            exit;

        ColumnNumber := 0;
        while UsersInUserGroups.Read() do begin
            // Add data to the chart
            Rec.AddColumn(Format(UsersInUserGroups.UserGroupCode)); // X-Axis data
            Rec.SetValue(UsersTxt, ColumnNumber, UsersInUserGroups.NumberOfUsers); // Y-Axis data
            ColumnNumber += 1;
        end;
        IsChartDataReady := true;
    end;
}

#endif