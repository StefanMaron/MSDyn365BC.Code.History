codeunit 802 "Online Map Management"
{

    trigger OnRun()
    begin
    end;

    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        ThisAddressTxt: Label '&This address';
        DirectionsFromLocationTxt: Label '&Directions from my location';
        OtherDirectionsTxt: Label '&Other';
        OtherMenuQst: Label '&Directions from my company,Directions to my &company,Directions from &another address,Directions to an&other address';
        Text002: Label 'There is no default Map setup.';
        ShowMapQst: Label 'Show map with:';
        Text007: Label 'Table %1 has not been set up to use Online Map.';
        Text008: Label 'The specified record could not be found.';
        Text015: Label 'Bing Maps';

    procedure MakeSelection(TableID: Integer; Position: Text[1000])
    var
        [RunOnClient]
        LocationProvider: DotNet LocationProvider;
        MainMenu: Text;
        Selection: Integer;
    begin
        if LocationProvider.IsAvailable then
            MainMenu := StrSubstNo('%1,%2,%3', ThisAddressTxt, DirectionsFromLocationTxt, OtherDirectionsTxt)
        else
            MainMenu := StrSubstNo('%1,%2', ThisAddressTxt, OtherDirectionsTxt);

        Selection := StrMenu(MainMenu, 1, ShowMapQst);
        case Selection of
            1:
                ProcessMap(TableID, Position);
            2:
                if LocationProvider.IsAvailable then
                    SelectAddress(TableID, Position, 4)
                else
                    ShowOtherMenu(TableID, Position);
            3:
                ShowOtherMenu(TableID, Position);
        end;
    end;

    local procedure ShowOtherMenu(TableID: Integer; Position: Text[1000])
    var
        Selection: Integer;
    begin
        Selection := StrMenu(OtherMenuQst, 1, ShowMapQst);
        case Selection of
            0:
                MakeSelection(TableID, Position);
            1:
                SelectAddress(TableID, Position, 3);
            2:
                SelectAddress(TableID, Position, 2);
            3:
                SelectAddress(TableID, Position, 1);
            4:
                SelectAddress(TableID, Position, 0);
        end;
    end;

    local procedure ProcessWebMap(TableNo: Integer; ToRecPosition: Text[1000])
    var
        Parameters: array[12] of Text[100];
        url: Text[1024];
        IsHandled: Boolean;
    begin
        GetSetup;
        BuildParameters(TableNo, ToRecPosition, Parameters, OnlineMapSetup."Distance In", OnlineMapSetup.Route);

        url := OnlineMapParameterSetup."Map Service";
        SubstituteParameters(url, Parameters);

        IsHandled := false;
        OnAfterProcessWebMap(url, IsHandled);
        if not IsHandled then
            HyperLink(url);
    end;

    local procedure ProcessWebDirections(FromNo: Integer; FromRecPosition: Text[1000]; ToNo: Integer; ToRecPosition: Text[1000]; Distance: Option Miles,Kilometers; Route: Option Quickest,Shortest)
    var
        Parameters: array[2, 12] of Text[100];
        url: Text[1024];
        IsHandled: Boolean;
    begin
        GetSetup;
        BuildParameters(FromNo, FromRecPosition, Parameters[1], Distance, Route);
        BuildParameters(ToNo, ToRecPosition, Parameters[2], Distance, Route);

        if FromNo = DATABASE::Geolocation then begin
            url := OnlineMapParameterSetup."Directions from Location Serv.";
            SubstituteGPSParameters(url, Parameters[1]);
            SubstituteParameters(url, Parameters[2]);
        end else begin
            url := OnlineMapParameterSetup."Directions Service";
            SubstituteParameters(url, Parameters[1]);
            SubstituteParameters(url, Parameters[2]);
        end;

        IsHandled := false;
        OnAfterProcessWebDirections(url, IsHandled);
        if not IsHandled then
            HyperLink(url);
    end;

    procedure ProcessMap(TableNo: Integer; ToRecPosition: Text[1000])
    begin
        TestSetupExists;
        ProcessWebMap(TableNo, ToRecPosition);
    end;

    procedure ProcessDirections(FromNo: Integer; FromRecPosition: Text[1000]; ToNo: Integer; ToRecPosition: Text[1000]; Distance: Option; Route: Option)
    begin
        TestSetupExists;
        ProcessWebDirections(FromNo, FromRecPosition, ToNo, ToRecPosition, Distance, Route);
    end;

    procedure BuildParameters(TableNo: Integer; RecPosition: Text[1000]; var Parameters: array[12] of Text[100]; Distance: Option Miles,Kilometers; Route: Option Quickest,Shortest)
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        i: Integer;
    begin
        Clear(Parameters);
        if ValidAddresses(TableNo) then
            GetAddress(TableNo, RecPosition, Parameters)
        else
            Error(Text007, Format(TableNo));
        if TableNo = DATABASE::Geolocation then
            exit;
        OnlineMapSetup.Get;
        OnlineMapSetup.TestField("Map Parameter Setup Code");
        OnlineMapParameterSetup.Get(OnlineMapSetup."Map Parameter Setup Code");
        CompanyInfo.Get;

        if Parameters[5] = '' then
            Parameters[5] := CompanyInfo."Country/Region Code";
        if CountryRegion.Get(CopyStr(Parameters[5], 1, MaxStrLen(CountryRegion.Code))) then
            Parameters[6] := CountryRegion.Name;

        if OnlineMapParameterSetup."URL Encode Non-ASCII Chars" then
            for i := 1 to 6 do
                Parameters[i] := CopyStr(URLEncode(Parameters[i]), 1, MaxStrLen(Parameters[i]));

        Parameters[7] := GetCultureInfo;
        if OnlineMapParameterSetup."Miles/Kilometers Option List" <> '' then
            Parameters[8] := SelectStr(Distance + 1, OnlineMapParameterSetup."Miles/Kilometers Option List");
        if OnlineMapParameterSetup."Quickest/Shortest Option List" <> '' then
            Parameters[9] := SelectStr(Route + 1, OnlineMapParameterSetup."Quickest/Shortest Option List");
    end;

    local procedure GetAddress(TableID: Integer; RecPosition: Text[1000]; var Parameters: array[12] of Text[100])
    var
        Geolocation: Record Geolocation;
        Location: Record Location;
        RecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeGetAddress(TableID, RecPosition, Parameters, IsHandled);
        if IsHandled then
            exit;

        RecordRef.Open(TableID);
        RecordRef.SetPosition(RecPosition);
        if not RecordRef.Find('=') then
            Error(Text008);

        case TableID of
            DATABASE::Location:
                begin
                    RecordRef.SetTable(Location);
                    Parameters[1] := Format(Location.Address);
                    Parameters[2] := Format(Location.City);
                    Parameters[3] := Format(Location.County);
                    Parameters[4] := Format(Location."Post Code");
                    Parameters[5] := Format(Location."Country/Region Code");
                end;
            DATABASE::Customer:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::Vendor:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::"Company Information":
                SetParameters(RecordRef, Parameters, 4, 6, 31, 30, 36);
            DATABASE::Resource:
                SetParameters(RecordRef, Parameters, 6, 8, 54, 53, 59);
            DATABASE::Job:
                SetParameters(RecordRef, Parameters, 59, 61, 63, 64, 67);
            DATABASE::"Ship-to Address":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::"Order Address":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::"Bank Account":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::Contact:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            DATABASE::Employee:
                SetParameters(RecordRef, Parameters, 8, 10, 12, 11, 25);
            DATABASE::Geolocation:
                begin
                    RecordRef.SetTable(Geolocation);
                    Parameters[10] := Format(Geolocation.Latitude, 0, 2);
                    Parameters[11] := Format(Geolocation.Longitude, 0, 2);
                end;
        end;

        OnAfterGetAddress(TableID, RecPosition, Parameters, RecordRef);
    end;

    local procedure ValidAddresses(TableID: Integer): Boolean
    var
        IsValid: Boolean;
    begin
        OnBeforeValidAddress(TableID, IsValid);
        if IsValid then
            exit(true);

        IsValid :=
          TableID in [DATABASE::"Bank Account",
                      DATABASE::"Company Information",
                      DATABASE::Contact,
                      DATABASE::Customer,
                      DATABASE::Employee,
                      DATABASE::Job,
                      DATABASE::Location,
                      DATABASE::Resource,
                      DATABASE::"Ship-to Address",
                      DATABASE::"Order Address",
                      DATABASE::Vendor,
                      DATABASE::Geolocation];

        OnAfterValidAddress(TableID, IsValid);
        exit(IsValid);
    end;

    local procedure URLEncode(InText: Text[250]): Text[250]
    var
        SystemWebHttpUtility: DotNet HttpUtility;
    begin
        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility;
        exit(CopyStr(SystemWebHttpUtility.UrlEncode(InText), 1, MaxStrLen(InText)));
    end;

    local procedure GetCultureInfo(): Text[30]
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(WindowsLanguage);
        exit(CopyStr(CultureInfo.ToString, 1, 30));
    end;

    local procedure TestSetupExists(): Boolean
    var
        OnlineMapSetup: Record "Online Map Setup";
    begin
        if not OnlineMapSetup.Get then
            Error(Text002);
        exit(true);
    end;

    procedure TestSetup(): Boolean
    var
        OnlineMapSetup: Record "Online Map Setup";
    begin
        exit(not OnlineMapSetup.IsEmpty);
    end;

    local procedure SelectAddress(TableNo: Integer; RecPosition: Text[1000]; Direction: Option "To Other","From Other","To Company","From Company","From my location")
    var
        CompanyInfo: Record "Company Information";
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapAddressSelector: Page "Online Map Address Selector";
        OnlineMapLocation: Page "Online Map Location";
        Distance: Option Miles,Kilometers;
        Route: Option Quickest,Shortest;
    begin
        if Direction in [Direction::"To Other", Direction::"From Other"] then begin
            if not (OnlineMapAddressSelector.RunModal = ACTION::OK) then
                exit;
            if OnlineMapAddressSelector.GetRecPosition = '' then
                exit;
            OnlineMapAddressSelector.Getdefaults(Distance, Route)
        end else begin
            OnlineMapSetup.Get;
            CompanyInfo.Get;
        end;

        case Direction of
            Direction::"To Other":
                ProcessDirections(
                  TableNo, RecPosition,
                  OnlineMapAddressSelector.GetTableNo, OnlineMapAddressSelector.GetRecPosition,
                  Distance, Route);
            Direction::"From Other":
                ProcessDirections(
                  OnlineMapAddressSelector.GetTableNo, OnlineMapAddressSelector.GetRecPosition,
                  TableNo, RecPosition,
                  Distance, Route);
            Direction::"To Company":
                ProcessDirections(
                  TableNo, RecPosition,
                  DATABASE::"Company Information", CompanyInfo.GetPosition,
                  OnlineMapSetup."Distance In", OnlineMapSetup.Route);
            Direction::"From Company":
                ProcessDirections(
                  DATABASE::"Company Information", CompanyInfo.GetPosition,
                  TableNo, RecPosition,
                  OnlineMapSetup."Distance In", OnlineMapSetup.Route);
            Direction::"From my location":
                begin
                    OnlineMapLocation.SetRecordTo(TableNo, RecPosition);
                    OnlineMapLocation.RunModal;
                end;
        end;
    end;

    procedure SubstituteParameters(var url: Text[1024]; Parameters: array[12] of Text[100])
    var
        ParameterName: Text;
        parameterNumber: Integer;
        ParmPos: Integer;
    begin
        for parameterNumber := 1 to ArrayLen(Parameters) do begin
            ParameterName := StrSubstNo('{%1}', parameterNumber);
            ParmPos := StrPos(url, ParameterName);

            if ParmPos > 1 then
                url :=
                  CopyStr(
                    CopyStr(url, 1, ParmPos - 1) + Parameters[parameterNumber] + CopyStr(url, ParmPos + StrLen(ParameterName)),
                    1, MaxStrLen(url));
        end;
    end;

    local procedure SubstituteGPSParameters(var url: Text[1024]; Parameters: array[12] of Text[100])
    var
        ParameterName: Text;
        parameterNumber: Integer;
        ParmPos: Integer;
    begin
        for parameterNumber := 10 to ArrayLen(Parameters) do begin
            ParameterName := StrSubstNo('{%1}', parameterNumber);
            ParmPos := StrPos(url, ParameterName);

            if ParmPos > 1 then
                url :=
                  CopyStr(
                    CopyStr(url, 1, ParmPos - 1) + Parameters[parameterNumber] + CopyStr(url, ParmPos + StrLen(ParameterName)),
                    1, MaxStrLen(url));
        end;
    end;

    procedure SetupDefault()
    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
    begin
        OnlineMapSetup.DeleteAll;
        OnlineMapParameterSetup.DeleteAll;
        InsertParam(
          'BING',
          Text015,
          'http://bing.com/maps/default.aspx?where1={1}+{2}+{6}&v=2&mkt={7}',
          'http://bing.com/maps/default.aspx?rtp=adr.{1}+{2}+{6}~adr.{1}+{2}+{6}&v=2&mkt={7}&rtop={9}~0~0',
          'http://bing.com/maps/default.aspx?rtp=pos.{10}_{11}~adr.{1}+{2}+{6}&v=2&mkt={7}&rtop={9}~0~0',
          false, '', '0,1',
          'http://go.microsoft.com/fwlink/?LinkId=519372');
        OnlineMapSetup."Map Parameter Setup Code" := 'BING';
        OnlineMapSetup.Insert;
    end;

    local procedure InsertParam("Code": Code[10]; Name: Text[30]; MapURL: Text[250]; DirectionsURL: Text[250]; DirectionsFromGpsURL: Text[250]; URLEncode: Boolean; MilesKilometres: Text[250]; QuickesShortest: Text[250]; Comment: Text[250])
    var
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
    begin
        OnlineMapParameterSetup.Init;
        OnlineMapParameterSetup.Code := Code;
        OnlineMapParameterSetup.Name := Name;
        OnlineMapParameterSetup."Map Service" := MapURL;
        OnlineMapParameterSetup."Directions Service" := DirectionsURL;
        OnlineMapParameterSetup."Directions from Location Serv." := DirectionsFromGpsURL;
        OnlineMapParameterSetup."URL Encode Non-ASCII Chars" := URLEncode;
        OnlineMapParameterSetup."Miles/Kilometers Option List" := MilesKilometres;
        OnlineMapParameterSetup."Quickest/Shortest Option List" := QuickesShortest;
        OnlineMapParameterSetup.Comment := Comment;
        OnlineMapParameterSetup.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleMAPRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        OnlineMapSetup: Record "Online Map Setup";
        RecRef: RecordRef;
    begin
        if not OnlineMapSetup.Get then begin
            if not OnlineMapSetup.WritePermission then
                exit;
            OnlineMapSetup.Init;
            OnlineMapSetup.Insert;
        end;
        RecRef.GetTable(OnlineMapSetup);

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        with OnlineMapSetup do begin
            if "Map Parameter Setup Code" = '' then
                ServiceConnection.Status := ServiceConnection.Status::Disabled;
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, TableCaption, '', PAGE::"Online Map Setup");
        end;
    end;

    local procedure GetSetup()
    begin
        OnlineMapSetup.Get;
        OnlineMapSetup.TestField("Map Parameter Setup Code");
        OnlineMapParameterSetup.Get(OnlineMapSetup."Map Parameter Setup Code");
    end;

    local procedure SetParameters(var RecordRef: RecordRef; var Parameters: array[12] of Text[100]; AddressFieldNo: Integer; CityFieldNo: Integer; CountyFieldNo: Integer; PostCodeFieldNo: Integer; CountryCodeFieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(AddressFieldNo);
        Parameters[1] := Format(FieldRef);
        FieldRef := RecordRef.Field(CityFieldNo);
        Parameters[2] := Format(FieldRef);
        FieldRef := RecordRef.Field(CountyFieldNo);
        Parameters[3] := Format(FieldRef);
        FieldRef := RecordRef.Field(PostCodeFieldNo);
        Parameters[4] := Format(FieldRef);
        FieldRef := RecordRef.Field(CountryCodeFieldNo);
        Parameters[5] := Format(FieldRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAddress(TableID: Integer; RecPosition: Text; var Parameters: array[12] of Text[100]; var RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessWebMap(url: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessWebDirections(url: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidAddress(TableID: Integer; var IsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAddress(TableID: Integer; RecPosition: Text; var Parameters: array[12] of Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidAddress(TableID: Integer; var IsValid: Boolean)
    begin
    end;
}

