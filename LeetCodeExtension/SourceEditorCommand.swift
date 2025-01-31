import Foundation
import XcodeKit
import SwiftHTMLtoMarkdown

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    override init() {
        super.init()
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let leetCodeService = LeetCodeService()
        
        leetCodeService.fetchRandomProblem { result in
            switch result {
            case .success(let problem):
                if let title = problem["title"] as? String,
                   let content = problem["content"] as? String,
                   let difficulty = problem["difficulty"] as? String,
                   let questionId = problem["questionId"] as? String {
                    let markdown = self.convertHTMLToMarkdown(content)
                    let formattedMarkdown = self.formatMarkdown(title: title, difficulty: difficulty, questionId: questionId, content: markdown)
                    
                    // Clear existing content
                    invocation.buffer.lines.removeAllObjects()
                    
                    // Add new content
                    invocation.buffer.lines.addObjects(from: formattedMarkdown.components(separatedBy: .newlines))
                    
                    completionHandler(nil)
                } else {
                    completionHandler(NSError(domain: "Invalid problem data", code: 0, userInfo: nil))
                }
            case .failure(let error):
                completionHandler(error)
            }
        }
    }
    
    func convertHTMLToMarkdown(_ html: String) -> String {
        var document = BasicHTML(rawHTML: html)
        do {
            try document.parse()
            let markdown = try document.asMarkdown()
            return markdown
        } catch {
            print("Error converting HTML to Markdown: \(error)")
            return html // Return original HTML if conversion fails
        }
    }
    
    func formatMarkdown(title: String, difficulty: String, questionId: String, content: String) -> String {
        let formattedMarkdown = """
        # LeetCode Problem #\(questionId): \(title)
        
        **Difficulty:** \(difficulty)
        
        ## Problem Description
        
        \(content)
        
        ## Solution
        
        ```
        // Your solution here
        ```
        """
        return formattedMarkdown
    }
}
