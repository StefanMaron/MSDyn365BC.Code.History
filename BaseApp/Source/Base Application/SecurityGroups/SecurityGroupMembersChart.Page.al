page 9858 "Security Group Members Chart"
{
    Caption = 'Users in Security Groups';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            usercontrol(BusinessChart; "Microsoft.Dynamics.Nav.Client.BusinessChart")
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(point: DotNet BusinessChartDataPoint)
                var
                    SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
                    SecurityGroup: Codeunit "Security Group";
                begin
                    SecurityGroup.GetMembers(SecurityGroupMemberBuffer);
                    SecurityGroupMemberBuffer.SetRange("Security Group Code", point.XValueString);
                    if not SecurityGroupMemberBuffer.FindFirst() then
                        exit;

                    Page.RunModal(Page::"Security Group Members", SecurityGroupMemberBuffer);
                    CurrPage.Update(); // refresh the charts with the eventual changes
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    UpdateData();
                end;

                trigger Refresh()
                begin
                    UpdateData();
                end;
            }
        }
    }


    trigger OnFindRecord(Which: Text): Boolean
    begin
        UpdateData();
    end;

    var
        BusinessChart: Codeunit "Business Chart";
        IsChartAddInReady: Boolean;
        UsersTxt: Label 'Users';
        SecurityGroupTxt: Label 'Security Group';

    local procedure UpdateData()
    begin
        if not IsChartAddInReady then
            exit;

        UpdateData(CurrPage.BusinessChart);
    end;

    local procedure UpdateData(DotNetBusinessChartAddIn: DotNet BusinessChartAddIn)
    var
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
        Index: Integer;
        ChartLabels: List of [Text];
        ChartValues: List of [Integer];
    begin
        BusinessChart.Initialize();
        BusinessChart.AddMeasure(UsersTxt, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);
        BusinessChart.SetXDimension(SecurityGroupTxt, Enum::"Business Chart Data Type"::String);

        SecurityGroup.GetGroups(SecurityGroupBuffer);
        SecurityGroup.GetMembers(SecurityGroupMemberBuffer);
        if SecurityGroupBuffer.FindSet() then
            repeat
                SecurityGroupMemberBuffer.SetRange("Security Group Code", SecurityGroupBuffer.Code);
                ChartLabels.Add(SecurityGroupBuffer.Code);
                ChartValues.Add(SecurityGroupMemberBuffer.Count());
            until SecurityGroupBuffer.Next() = 0;

        for Index := 1 to ChartLabels.Count() do begin
            BusinessChart.AddDataRowWithXDimension(ChartLabels.Get(Index));
            BusinessChart.SetValue(0, Index - 1, ChartValues.Get(Index));
        end;

        BusinessChart.Update(DotNetBusinessChartAddIn);
    end;
}

