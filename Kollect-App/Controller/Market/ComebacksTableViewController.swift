//
//  ComebacksTableViewController.swift
//  Kollect-App
//
//  Created by Daryl Khor on 15/05/2024.
//

import UIKit

class ComebacksTableViewController: UITableViewController {
    
    let CELL_COMEBACK = "comebackCell"
    // Reference: https://kpop-comebacks.heismauri.com/api
    let REQUEST_STRING = "https://kpop-comebacks.heismauri.com/api"
    
    var newComebacks = [ComebackData]()
    var comebacksByDate = [String: [ComebackData]]()
    var sortedDates = [String]()
    var indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        Task {
            await requestComebacksNamed()
            
            // Group comebacks by date
            for comeback in newComebacks {
                let date = getDate(date: comeback.date)
                comebacksByDate[date, default: []].append(comeback)
            }
            
            // Sort dates
            sortedDates = comebacksByDate.keys.sorted()
            
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // numberOfSections = number of dates
        return sortedDates.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = sortedDates[section]
        return comebacksByDate[date]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_COMEBACK, for: indexPath) as! ComebackTableViewCell
        let date = sortedDates[indexPath.section]
        let comebacks = comebacksByDate[date]!
        let comeback = comebacks[indexPath.row]
        
        cell.titleLabel.text = comeback.title
        cell.timeLabel.text = getTime(date: comeback.date)
        cell.timeLabel.textColor = .secondaryLabel
        
        cell.isUserInteractionEnabled = false
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedDates[section]
    }
    
    // Reference: https://stackoverflow.com/a/19173756
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .accent
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    /// Makes a network request to retrieve a list of comebacks based on a given name.
    ///
    /// This function constructs a URL request using the `REQUEST_STRING` constant, which should contain the API endpoint for retrieving comebacks.
    /// It then uses `URLSession.shared.data(for:)` to make the request and decode the response data into an array of `ComebackData` objects.
    /// The retrieved comebacks are stored in the `newComebacks` array, and the table view is reloaded to display the updated data.
    func requestComebacksNamed() async {
        // Check if the request URL is valid.
        guard let requestURL = URL(string: REQUEST_STRING) else {
            print("Invalid URL.")
            return
        }
        
        indicator.startAnimating()
        
        // Create a URL request.
        let urlRequest = URLRequest(url: requestURL)
        
        // Make the network request.
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            indicator.stopAnimating()
            
            // Decode the JSON data into an array of ComebackData objects.
            do {
                let decoder = JSONDecoder()
                let comebacks = try decoder.decode([ComebackData].self, from: data)
                newComebacks = comebacks
                tableView.reloadData()
                
            } catch let error {
                // Handle any errors that occur during decoding.
                print(error)
            }
        } catch let error {
            // Handle any errors that occur during the network request.
            print(error)
        }
    }
    
    /// Formats a Unix timestamp (in milliseconds) into a date string.
    /// - Parameter date: The Unix timestamp in milliseconds.
    /// - Returns: A string representing the date in the format "yyyy.MM.dd".
    func getDate(date: Double) -> String {
        let newDate = Date(timeIntervalSince1970: date/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: TimeZone.current.abbreviation()!)
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: newDate)
    }
    
    /// Formats a Unix timestamp (in milliseconds) into a time string.
    /// - Parameter date: The Unix timestamp in milliseconds.
    /// - Returns: A string representing the time in the format "h:mma".
    func getTime(date: Double) -> String {
        let newDate = Date(timeIntervalSince1970: date/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: TimeZone.current.abbreviation()!)
        dateFormatter.dateFormat = "h:mma"
        return dateFormatter.string(from: newDate)
    }
    
}
