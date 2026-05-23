//
//  Image+Images.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 02/04/2024.
//

import SwiftUI

// MARK: Common images and icons.

extension Image {
    
    static let fullLogo = Image("full_logo")
    static let splashLogo = Image("splash_logo")
    static let headerLogo = Image("header_logo")
    static let emailIcon = Image("email_icon")
    static let passwordIcon = Image("password_icon")
    static let countryFlag = Image("country_flag")
    static let phoneIcon = Image("phone_icon")
    static let personIcon = Image("person_icon")
    static let checkIcon = Image("check_ic")
    static let checkIconRed = Image("check_ic_red")
    static let checkIconYellow = Image("check_ic_yellow")
    static let uncheckIcon = Image("uncheck_ic")
    static let backArrow = Image("back_arrow_icon")
    static let successIcon = Image("success_icon")
    static let languageIcon = Image("language_ic")
    static let deleteAccountIcon = Image("delete_account_ic")
    static let logoutIcon = Image("logout_ic")
    static let qrCodeIcon = Image("qr_code_ic")
    static let merchantIcon = Image("store_account_ic")
    static let termsIcon = Image("terms_ic")
    static let debitBookIcon = Image("debit_book_ic")
    static let profileIcon = Image("user_ic")
    static let editImageIcon = Image("edit_image_ic")
    static let addProductIcon = Image("add_product_ic")
    static let categoriesPlaceholder = Image("categories_placeholder")
    static let nearbyStoresPlaceholder = Image("nearbyStores_placeholder")
    static let productPlaceholder = Image("product_placeholder")
    static let purchasesMonthIcon = Image("purchasesMonth _ic")
    static let todayPurchasesIcon = Image("today_purchases_ic")
    static let userIcon = Image("user_profile_ic")
    static let searchIcon = Image("search_ic")
    static let noDataImage = Image("no_data_im")
    static let noDataStoreImage = Image("no_date_store_im")
    static let trackLineIcon = Image("track_line_ic")
    static let trackPointIcon = Image("track_point_ic")
    static let storeIcon = Image("store_ic")
    static let invoiceIcon = Image("invoice_ic")
    static let trackEmptyIcon = Image("track_empty_ic")
    static let plusIcon = Image("add_ic")
    static let productDetailsBackgroundIcon = Image("background_product_im")
    static let muinsIcon = Image("muins_ic")
    static let noDataCartImage = Image("no_data_cart_im")
    static let muinsCartIcon = Image("muins_cart_ic")
    static let plusCartIcon = Image("plus_cart_ic")
    static let removeCartIcon = Image("remove_cart_ic")
    static let mobileIcon = Image("store_phone_ic")
    static let locationIcon = Image("store_location_ic")
    static let viewMapIcon = Image("view_map_ic")
    static let radioFillIcon = Image("radio-fill-ic")
    static let radioIcon = Image("radio-ic")
    static let storeNameIcon = Image("store_name_ic")
    static let customerIcon = Image("customer_ic")
    static let depitIcon = Image("depit_ic")
    static let orderIcon = Image("order_ic")
    static let qrCodeStoreIcon = Image("qr_code_ic")
    static let stockItemsIcon = Image("stock_items_ic")
    static var addIcon = Image("add_store_ic")
    static var storeUserIcon = Image("store_user_ic")
    static var barcodeIcon = Image("barcode_ic")
    
    // User profile icons
    static let userIconWhite = Image(systemName: "person.fill")
    
    // Navigation icons (if not already defined)
    static let backIcon = Image(systemName: "chevron.left")
    
    // Debit book icons
    static let calendarIcon = Image(systemName: "calendar")
    static let debitIcon = Image(systemName: "exclamationmark.triangle.fill")
    
    //Item request icons
    static let imagePickerIcon = Image("imagePicker")
    
    // supplier icons
    static let supplierBanner = Image("supplier_banner")
    static let locationStoreIcon = Image("location_store_ic")
    static let dateIcon = Image("date_ic")
    static let totalIcon = Image("total_ic")
    static let cashierIcon = Image("cashier_ic")
    static let receiptIcon = Image("receipt_ic")
    static let billsIcon = Image("bills_ic")
}

// MARK: Store Icon
extension UIImage {
    static let addSupplierIcon = UIImage(resource: .addSupplierIc)
    static let itemRequestIcon = UIImage(resource: .itemRequestIc)
    static let storeSettingsIcon = UIImage(resource: .storeSettingsIc)
}

extension UIImage {
    
    // tabbar icons
    static let homeIcon = UIImage(resource: .homeIc)
    static let cartIcon = UIImage(resource: .cartIc)
    static let searchIcon = UIImage(resource: .searchIc)
    static let trackIcon = UIImage(resource: .trackIc)
    static let moreIcon = UIImage(resource: .moreIc)
}
