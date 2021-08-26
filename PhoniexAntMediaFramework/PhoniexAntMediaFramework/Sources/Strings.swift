//
//  Strings.swift
//  VoW
//
//  Created by Jayesh Mardiya on 21/08/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation

extension String {

    // Login Screen (Same for presenter also)
    static let buttonLoginMenu = "BtnTitle_Login".localized
    static let buttonLogin = "BtnTitle_Login".localized.uppercased()
    static let labelUsername = "Label_Username".localized
    static let labelPassword = "Label_Password".localized
    static let labelRemember = "Label_Remember".localized

    // Menu Screen
    static let buttonWifiStream = "BtnTitle_CreateLocalStream".localized
    static let buttonJoinWifiStream = "BtnTitle_JoinWiFiStream".localized
    static let buttonJoinInternetStream = "BtnTitle_JoinInternetStream".localized
    static let buttonMemberAreaMenu = "BtnTitle_MemebersArea".localized
    static let labelSubAccountsMenu = "Label_SubAccounts".localized
    static let buttonStartWifiStreamMenu = "BtnTitle_StartWiFiStream".localized
    static let buttonInternetStream = "BtnTitle_CreateRemoteStream".localized
    static let buttonJoinPresenter = "BtnTitle_JoinPresenter".localized
    static let buttonManageInternetStream = "BtnTitle_ManageInternetStreams".localized
    static let buttonManageSubAccountsMenu = "BtnTitle_ManageSubAccounts".localized
    static let buttonLogoutMenu = "BtnTitle_Logout".localized
    static let labelMenuHeaderTitleStream = "Label_Stream".localized
    static let labelMenuHeaderTitleAccount = "Label_Account".localized
    static let alertTitleLogout = "AlertTitle_Logout".localized
    static let alertDescLogout = "AlertDesc_Logout".localized
    static let alertDesc_WrongCred = "AlertDesc_WrongCred".localized
    static let alertDesc_AlreadyAuthorized = "AlertDesc_AlreadyAuthorized".localized
    static let alertDesc_AccountExpired = "AlertDesc_AccountExpired".localized
    static let alertDesc_ToSoon = "AlertDesc_ToSoon".localized
    static let buttonTitlePrivacyPolicy = "BtnTitle_PrivacyPolicy".localized
    static let buttonTitleTermsConditions = "BtnTitle_TermsConditions".localized
    
    static let buttonTitleOK = "BtnTitle_OK".localized
    
    static let labelTitleCreateStream = "BtnTitle_CreateLocalStream".localized
    static let labelTitleAskQuestion = "Label_AskQuestion".localized
    static let labelTitleWaitingForStream = "Label_WaitingForStream".localized
    static let labelTitleSentMessage = "Label_MessageSent".localized
    static let labelTitleYourName = "Label_YourName".localized
    static let labelTitleYourMessage = "Label_YourMessage".localized
    static let buttonTitleSendMessage = "BtnTitle_SendMessage".localized
    
    static let alertTitleShare = "AlertTitle_Share".localized
    static let alertTitleFromCamera = "BtnTitle_Camera".localized
    static let alertTitleFromGallery = "BtnTitle_Gallery".localized
    static let alertTitleFromFile = "BtnTitle_FileSystem".localized
    
    static let labelWaitingForPresenter = "Label_WaitingPresenter".localized
    
    static let alertButtonTitle_Close = "BtnTitle_Close".localized
    static let alertButtonTitle_Upgrade = "BtnTitle_Upgrade".localized
    static let alertDesc_Upgrade = "AlertTitle_Upgrade".localized
    
    static let alertTitleDeleteSubAccount = "AlertTitle_DeleteSubAccount".localized
    static let alertTitleDeleteRoom = "AlertTitle_DeleteRoom".localized
    static let alertTitleCreateRoom = "AlertTitle_CreateRoom".localized
    
    // Listner Wifi Page
    static let labelNoWifi = "Label_WiFiNotAvailable".localized
    static let labelWifi = "Label_WiFiAvailable".localized

    static let labelConnectionSuccess = "Label_ConnectedToInternet".localized
    
    // Listener Internet stream
    static let buttonJoinTitle = "BtnTitle_Join".localized
    static let alertTitleCloseStream = "AlertTitle_CloseStream".localized
    static let alertDescCloseStream = "AlertDesc_CloseStream".localized
    
    // Presenter Wifi Stream
    static let streamingName = "Label_StreamName".localized
    static let startStream = "BtnTitle_Start".localized
    static let labelNumberOfListenerTitle = "Label_NumberOfListeners".localized
    static let labelMessagesTitle = "Label_Messages".localized
    
    // Presenter Internet Stream
    static let labelConnecting = "Label_Connecting".localized
    static let alertStopStreamingTitle = "AlertTitle_StopStream".localized
    static let alertStopStreamingDesc = "AlertDesc_StopStream".localized
    static let alertTitleCreateSubAccount = "AlertTitle_CreateSubAccount".localized
    static let alertDescDeleteSubAccount = "AlertDesc_DeleteSubAccount".localized
    
    static let alertButtonKeepIt = "Alert_ButtonKeepIt".localized
    static let alertButtonStopIt = "Alert_ButtonStopIt".localized
    
    static let alertDescFileSent = "AlertTitle_FileSent".localized
    static let alertDescFileNotSent = "AlertTitle_FileNotSent".localized
    
    // Presenter Internet Stream
    static let buttonTitleScheduleNewStream = "BtnTitle_ScheduleNewStream".localized
    
    // Manage Internet stream
    static let buttonTitleCreateSubAccount = "BtnTitle_CreateSubAccount".localized
    static let labelSubAccountName = "Label_SubAccountName".localized
    static let buttonSubmitTitle = "BtnTitle_Submit".localized
    static let buttonTitleCancel = "BtnTitle_Cancel".localized
    static let buttonOkTitle = "BtnTitle_OK".localized
    
    static let labelTitleNoStreaming = "Label_NoStreamAvailable".localized
    static let labelTitleAvailableStreamings = "Label_AvailableStreaming".localized
    
    static let labelNoMoreMessage = "Label_EmptyMessageList".localized
    static let buttonTitleDelete = "BtnTitle_Delete".localized
    
    static let labelAccountExpired = "Label_AccountExpired".localized
    static let labelAccountExpiry = "Label_AccountExpiry".localized
    static let labelScanQRToLogin = "Label_ScanQrCode".localized
    static let alertDescFileSentError = "AlertTitle_CantSendFile".localized
    static let labelInternetConnectionNotAvailable = "Label_NetworkNotAvailable".localized
    
    static let buttonStopStreaming = "Btn_Stop_Streaming".localized
    static let labelConnectedTo = "Label_ConnectedTo".localized
    static let labelConnectionStatus = "Label_Connection_Status".localized
    
    static let alertTitleCantConnectBox = "AlertTitle_CantConnectBox".localized
    static let alertDescCantConnectBox = "AlertDesc_CantConnectBox".localized
    static let alertDescSomethingWrong = "AlertDesc_SomethingWrong".localized
    static let alertDescLimitExceeded = "AlertDesc_LimitExceeded".localized
    static let labelConnectedWith = "Label_ConnectedWith".localized
    static let labelSearchingVoxBox = "Label_SearchingVoxBox".localized
    static let labelVoxBoxConnecting = "Label_VoxBoxConnecting".localized
    static let alertTitleInValidPasscode = "AlertTitle_InValidPasscode".localized
    static let alertDescInValidPasscode = "AlertDesc_InValidPasscode".localized
    static let alertDescCantConnectSSID = "AlertDesc_CantConnectSSID".localized
    static let alertDescVoxBoxNotFound = "AlertDesc_VoxBoxNotFound".localized
    static let alertTitleVoxBoxNotFount = "AlertTitle_VoxBox_Not_Fount".localized
    static let searchFieldPlacehoderText = "Search_PlaceholderText".localized
    
    static let alertTitleWhatsapp = "AlertTitle_Whatsapp".localized
    static let alertDescWhatsapp = "AlertDesc_Whatsapp".localized
    static let alertButtonTitleInstall = "Alert_ActionTitle_Install".localized
    static let labelDifferentVoxBox = "Label_DifferentVoxBox".localized
    static let buttonTitleListenStream = "BtnTitle_ListenStream".localized
    
    static let alertTitleNetworkError = "AlertTitle_NetworkError".localized
    static let alertDescNetworkError = "AlertDesc_NetworkError".localized
    
    static let labelFetchingVoxBox = "Label_FetchingVoxBox".localized
    static let alertDescStreamNotFound = "AlertDesc_StreamNotFound".localized
    static let labelServiceMessageConnecting = "Label_ServiceMsgConnecting".localized
}
